# Capstone Appendix - Supporting Materials (Illustrative Examples)

**Student:** Mrunmay Muduli - MS in Business Analytics, University of Cincinnati
**Capstone:** Business Intelligence Analytics at Nucor Business Technology
**Readers:** Professor Rokey (first) | Mohammad Tahir Madni Mohammad, Nucor Business Technology (second)

---

## Important note on confidentiality

The capstone project was performed on internal enterprise systems at Nucor
Business Technology. Company policy does not permit sharing actual screenshots,
code, or data externally. Per Professor Rokey's guidance, **all materials in
this folder are recreated examples using fully fictional names, schemas, and
data** that illustrate the structure, techniques, and tools used in the real
implementation. No real system names, table names, column names, report names,
or data values appear anywhere in this folder - everything is invented for
illustration only.

---

## Contents

**01_Architecture/**
- `architecture_diagram.png` - end-to-end flow: enterprise source -> continuous
  export feed (raw) -> Fabric lakehouses (staged/reference/published layers)
  -> Power BI, with the historical database input and daily orchestration.
- `architecture_overview.md` - written walkthrough of the architecture.

**02_SQL_Examples/**
- `01_pub_ledger_activity.sql` - raw-to-published transformation (staging
  joins, category filter, full-refresh and incremental MERGE patterns).
- `02_pub_report_tables.sql` - published reporting tables/views feeding the
  semantic model, combining raw + staged + reference inputs.
- `03_quality_checks.sql` - reconciliation, null/duplicate, and freshness
  checks that protect reporting accuracy during migration.

**03_Notebook_and_Pipeline/**
- `01_Published_Layer_Notebook.ipynb` - PySpark/Spark SQL notebook recreating
  the daily published-layer build pattern.
- `02_pipeline_configuration.md` + `pipeline_diagram.png` - parameterized loop
  copy pipeline (historical database -> lakehouse), morning schedule, failure
  notifications.

**04_PowerBI_Model_and_Reports/**
- `star_schema.png` + `semantic_model_documentation.md` - semantic model
  design, incremental refresh, shared-model publishing pattern.
- `report_mock_adjustment_overview.png`, `report_mock_movement_detail.png` -
  report mockups with artificial data.

---

## Tools demonstrated
Microsoft Fabric (Lakehouse, Data Pipelines, Notebooks) | continuous export
integration for a cloud enterprise system | Spark SQL / PySpark | Delta Lake |
relational database migration | Power BI (semantic models, incremental
refresh, drill-through reporting).
