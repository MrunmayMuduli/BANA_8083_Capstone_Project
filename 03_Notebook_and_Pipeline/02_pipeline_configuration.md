# Copy Pipeline Configuration - Historical Database to Analytics Lakehouse

**ILLUSTRATIVE EXAMPLE** - fully fictional names throughout. This document
recreates only the structure of the Fabric Data Pipeline built during the
capstone project. See `pipeline_diagram.png` for the visual layout.

## Purpose
Certain reporting inputs originate in a historical relational database
(pre-migration business rules and reference tables) rather than from the
primary enterprise source. This pipeline copies those tables into the
analytics lakehouse each morning and triggers a notebook that cleanses and
merges them into curated tables.

## Structure

| Component | Configuration (recreated) |
|---|---|
| Pipeline parameter | `copyItems` : **Array** - e.g. `[{"sourceTable":"dbo.DispatchLines","targetTable":"import_stage.DispatchLineHistory"}, ...]` |
| Loop activity | Iterates `copyItems`; each iteration runs a Copy Data activity followed by a Notebook activity |
| Copy Data activity | Source: historical database table (via gateway/connection) -> Sink: lakehouse landing area |
| Notebook activity | Runs the published-layer notebook (`01_Published_Layer_Notebook.ipynb`), passing the current item as a parameter |

## Schedule & Monitoring

| Setting | Value (recreated) |
|---|---|
| Schedule | Each morning at 05:30 UTC - **On** |
| Job type | Pipeline |
| Failure notifications | E-mail alert to the pipeline owner when a scheduled run fails |
| Run history | Reviewed in Fabric Monitor after each run |

## Why this design
- **Parameterization** - adding a new table to the daily copy requires only a
  new entry in `copyItems`; no pipeline redesign.
- **Separation of concerns** - the Copy activity handles movement; the notebook
  handles cleansing, deduplication, and Delta merge logic; downstream notebooks
  combine raw, import_stage, and import_ref inputs into the final
  `pub_reports` tables (mix varies per report).
- **Reliability** - the morning schedule plus failure e-mail keeps curated data
  current without manual intervention, which downstream Power BI refresh
  depends on.
