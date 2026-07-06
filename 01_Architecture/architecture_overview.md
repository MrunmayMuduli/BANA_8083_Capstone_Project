# Architecture Overview - Enterprise Source to Power BI on Microsoft Fabric

**ILLUSTRATIVE EXAMPLE** - all workspace, lakehouse, schema, and table names
are fully fictional and invented for this document. The actual implementation
is confidential to the sponsoring company; this recreation preserves the
structure and techniques while using invented details throughout. See
`architecture_diagram.png` for the visual.

## Data flow

1. **Enterprise source system.** Business transactions and master data: items,
   warehouse activity, dispatches, purchasing, financial entries.

2. **Continuous export feed.** Selected source tables are continuously exported
   as **raw**, append-only data, partitioned by **year**. Sync status and
   last-refresh timestamps are monitored per table.

3. **Raw lakehouse (`corelanding_lh`).** Landing zone in Microsoft Fabric. Raw
   exported tables are exposed under schemas such as `fin_ledger` (financial
   entries) and `wh_ops` (warehouse movement) with no transformation applied -
   a faithful, auditable copy of source.

4. **Analytics lakehouse (`insights_lh`).** A second lakehouse dedicated to
   curated layers and reporting, organized in three schema roles:
   - **import_stage** - tables copied directly from a historical relational
     database (daily copy pipeline), such as the item catalog and batch
     registry.
   - **import_ref** - reference and lookup tables copied from the same
     database, carrying pre-migration business rules.
   - **pub_reports** - the **published reporting tables**, built by scheduled
     PySpark/Spark SQL notebooks. Each table combines whatever mix of raw,
     import_stage, and import_ref inputs its target report requires - the
     input mix changes per report.

5. **Historical database input.** Business rules and reference tables that
   predate the migration are copied in daily by a parameterized Data Pipeline
   (loop + Copy + Notebook - see folder 03) into the **import_stage** and
   **import_ref** schemas, preserving pre-migration reporting rules inside the
   new platform.

6. **Power BI semantic model.** Built on the **pub_reports** tables in the
   lakehouse (live connection): star schema with conformed dimensions (Item
   Catalog, Calendar, Warehouse, Batch Registry, Reporting Period) and
   movement/activity facts. Incremental refresh is configured with the
   standard range parameters.

7. **Reports.** Published to the workspace and connected **live** to the shared
   semantic model - e.g. a Warehouse Movement Detail report (record-level
   detail with drill-through) and an Adjustment & Count Overview (mass and cost
   impact by warehouse and activity type, with a unit toggle).

## Refresh & operations

- Daily pipeline run each morning executes copies and notebook loads.
- Semantic model refresh follows the data load; reports always reflect the
  latest published data with a visible as-of timestamp.
- Failure e-mail notifications and Fabric run history provide monitoring.

## Design principles demonstrated

- **Layered lakehouse architecture** (raw -> staged/reference -> published) for
  auditability and reuse.
- **Single source of truth** - one semantic model serving multiple reports.
- **Migration safety** - pre-migration business rules reproduced and validated
  inside Fabric before cutover (see validation queries in folder 02).
