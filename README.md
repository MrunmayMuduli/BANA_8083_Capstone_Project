# Capstone Appendix - Supporting Materials (Illustrative Examples)

**Student:** Mrunmay Muduli - MS in Business Analytics, University of Cincinnati
**Capstone:** Business Intelligence Analytics at Nucor Business Technology
**Readers:** Professor Rokey (first) · Mohammad Tahir Madni Mohammad, Nucor Business Technology (second)

---

## Important note on confidentiality

The capstone project was performed on internal enterprise systems at Nucor
Business Technology. Company policy does not permit sharing actual screenshots,
code, or data externally. Per Professor Rokey's guidance, **all materials in this
folder are recreated examples using artificial names and artificial data** that
faithfully illustrate the structure, techniques, and tools used in the real
implementation. No confidential information is included.

---

## Contents

**01_Architecture/**
- `architecture_diagram.png` - end-to-end flow: D365 → Synapse Link (bronze) →
  Fabric lakehouses (silver/gold) → Power BI, with the legacy SQL Server input
  and daily orchestration.
- `architecture_overview.md` - written walkthrough of the architecture.

**02_SQL_Examples/**
- `01_silver_inventory_journal_fact.sql` - bronze→silver transformation
  (staging joins, posting-type filter, full-refresh and incremental MERGE patterns).
- `02_gold_reporting_views.sql` - gold-layer reporting tables/views feeding the
  semantic model.
- `03_data_validation_checks.sql` - reconciliation, null/duplicate, and
  freshness checks that protect reporting accuracy during migration.

**03_Notebook_and_Pipeline/**
- `01_Silver_Load_Notebook.ipynb` - PySpark/Spark SQL notebook mirroring the
  daily silver-load pattern.
- `02_pipeline_configuration.md` + `pipeline_diagram.png` - parameterized
  ForEach copy pipeline (SQL Server → lakehouse), daily 6:00 AM schedule,
  failure notifications.

**04_PowerBI_Model_and_Reports/**
- `star_schema.png` + `semantic_model_documentation.md` - semantic model design,
  incremental refresh (RangeStart/RangeEnd), shared-model publishing pattern.
- `report_mock_journal_summary.png`, `report_mock_rollforward_details.png` -
  report mockups with artificial data.

---

## Tools demonstrated
Microsoft Fabric (Lakehouse, Data Pipelines, Notebooks) · Azure Synapse Link for
Dataverse · Spark SQL / PySpark · Delta Lake · SQL Server · Power BI (semantic
models, incremental refresh, drill-through reporting).
