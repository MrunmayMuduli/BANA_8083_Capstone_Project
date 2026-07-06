# Copy Pipeline Configuration — SQL Server ➜ Analytics Lakehouse

**ILLUSTRATIVE EXAMPLE** — artificial names throughout. This document recreates the
structure of the Fabric Data Pipeline built during the capstone project. See
`pipeline_diagram.png` for the visual layout.

## Purpose
Certain silver-level tables originate in a legacy SQL Server database (business
logic and reference tables) rather than from Dynamics 365. This pipeline copies
those tables into the analytics lakehouse each day and triggers a notebook that
cleanses and merges them into the silver_src and gold_src schemas; notebooks then build final rpt_gold reporting tables from a per-report mix of bronze, silver_src, and gold_src inputs.

## Structure

| Component | Configuration (recreated) |
|---|---|
| Pipeline parameter | `tableList` : **Array** — e.g. `[{"source":"dbo.PackingSlipLines","target":"silver_src.PackingSlipLineTrans_Fact"}, ...]` |
| ForEach activity | Iterates `tableList`; each iteration runs a Copy Data activity followed by a Notebook activity |
| Copy Data activity | Source: SQL Server table (via gateway/connection) → Sink: lakehouse staging area |
| Notebook activity | Runs the silver-load notebook (`01_Silver_Load_Notebook.ipynb`), passing the current table item as a parameter |

## Schedule & Monitoring

| Setting | Value (recreated) |
|---|---|
| Schedule | Every day, 6:00 AM, time zone (UTC-05:00) Eastern Time — **On** |
| Job type | Pipeline |
| Failure notifications | E-mail alert to the pipeline owner when a scheduled run fails |
| Run history | Reviewed in Fabric Monitor after each daily run |

## Why this design
- **Parameterization** — adding a new table to the daily copy requires only a new
  entry in `tableList`; no pipeline redesign.
- **Separation of concerns** — the Copy activity handles movement; the notebook
  handles cleansing, deduplication, and Delta merge logic.
- **Reliability** — daily schedule plus failure e-mail keeps curated data current
  without manual intervention, which downstream Power BI refresh depends on.
