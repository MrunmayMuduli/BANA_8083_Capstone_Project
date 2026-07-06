# Architecture Overview - D365 to Power BI on Microsoft Fabric

**ILLUSTRATIVE EXAMPLE** - all workspace, lakehouse, and table names are artificial.
The actual implementation is confidential to Nucor Business Technology; this
recreation preserves the structure and techniques while using invented details.
See `architecture_diagram.png` for the visual.

## Data flow

1. **Dynamics 365 F&O (source ERP).** Transactional and master data: products,
   inventory, shipments, procurement, financial journals.

2. **Azure Synapse Link for Dataverse.** Selected D365 tables (100+ in the real
   implementation) are continuously exported as **bronze**, append-only raw data,
   partitioned by **Year**. Sync status and last-synchronized timestamps are
   monitored per table.

3. **Bronze lakehouse (`mfg_prod`).** Landing zone in Microsoft Fabric. Raw D365
   tables are exposed under a `finop` schema (e.g. `GeneralJournalEntry`,
   `InventJournalTrans`, `MainAccount`) with no transformation applied - a
   faithful, auditable copy of source.

4. **Analytics lakehouse (`MFG_ANALYTICS`).** A second lakehouse dedicated to
   curated layers and reporting, organized in three schema roles:
   - **silver_src** - silver-level tables copied directly from the legacy SQL
     Server database (daily copy pipeline), preserving cleansed source data.
   - **gold_src** - gold-level tables copied directly from SQL Server, carrying
     the legacy business/reporting logic into the new platform.
   - **rpt_gold** - the **final reporting tables**, built by scheduled
     PySpark/Spark SQL notebooks. Each table combines whatever mix of bronze
     (D365), silver_src, and gold_src inputs its target report requires - the
     input mix changes per report.

5. **Legacy SQL Server input.** Business logic and reference tables that predate
   the migration are copied in daily by a parameterized Data Pipeline
   (ForEach + Copy + Notebook - see folder 03) into the **silver_src** and
   **gold_src** schemas, preserving legacy reporting rules inside the new
   platform.

6. **Power BI semantic model.** Built on the **rpt_gold** reporting tables in
   the lakehouse (Direct Lake / live
   connection): star schema with conformed dimensions (Product, Transaction Date,
   Inventory Site, Tag, Fiscal Period) and inventory facts. Incremental refresh is
   configured with `RangeStart` / `RangeEnd` parameters.

7. **Reports.** Published to the workspace and connected **live** to the shared
   semantic model - e.g. an Inventory Rollforward report (transaction-level detail
   with drill-through) and an Inventory Journals summary (adjustment weight and
   cost by site and journal type, with an LBS/Tons toggle).

## Refresh & operations

- Daily pipeline run at 6:00 AM ET executes copies and notebook loads.
- Semantic model refresh follows the data load; reports always reflect the
  latest curated data with a visible source cut-off timestamp.
- Failure e-mail notifications and Fabric run history provide monitoring.

## Design principles demonstrated

- **Medallion architecture** (bronze → silver → gold) for auditability and reuse.
- **Single source of truth** - one semantic model serving multiple reports.
- **Migration safety** - legacy SQL Server logic reproduced and validated inside
  Fabric before cutover (see validation queries in folder 02).
