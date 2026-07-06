# Power BI Semantic Model & Reports — Documentation

**ILLUSTRATIVE EXAMPLE** — artificial table, column, site, and user names.
See `star_schema.png`, `report_mock_journal_summary.png`, and
`report_mock_rollforward_details.png` for visuals.

## Semantic model (star schema)

**Fact tables**
- `Inventory Rollforward` — inventory quantity (native, lb, ton), length/width,
  posted-by, keyed to product / site / date / tag.
- `Inventory Journal Transaction` — adjustment weight and cost by journal type
  (Counting, Inventory adjustment, Movement).

**Dimensions**
- `Product` — item #, item group/type, product name, UOM.
- `Transaction Date` — calendar + fiscal attributes (month, period, fiscal year).
- `Inventory Site` — site key, name, legal entity.
- `Tag` — mill/master tag #, heat #, disposition code.
- `Fiscal Period` — period boundaries used for period-based slicers.

**Parameters & refresh**
- `RangeStart` / `RangeEnd` datetime parameters drive **incremental refresh** on
  the large fact tables (only recent partitions reprocess on each refresh).
- A start-date parameter limits history loaded into the model.
- The model is **published to the workspace once** and reused: reports connect
  live to the shared semantic model rather than embedding their own copies —
  one version of business logic and measures for all reports.

## Reports (recreated as mockups)

**Inventory Rollforward — Transaction Details**
- Slicers: fiscal period, inventory site, item number.
- Detail grid: transaction date, item, tag number, length/width, transaction
  type/number, weight, posted by.
- Drill-through pages: rollforward by item number; transaction detail.

**Inventory Journals Summary**
- KPI cards: total adjustments, inventory adjustments, cycle-count adjustments,
  movement journals — shown both in weight (lb) and cost ($).
- Weight-unit toggle (LBS / Tons) implemented as a field parameter.
- Clustered bar chart: adjustment weight by site and journal type.
- Site quick-filter buttons and posted-date range slicer.

## Why this design
A single governed semantic model with incremental refresh keeps report
performance high while guaranteeing every report shows identical, validated
numbers — the central goal of the migration.
