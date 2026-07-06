# Power BI Semantic Model & Reports - Documentation

**ILLUSTRATIVE EXAMPLE** - fully fictional table, column, warehouse, and user
names. See `star_schema.png`, `report_mock_adjustment_overview.png`, and
`report_mock_movement_detail.png` for visuals.

## Semantic model (star schema)

**Fact tables**
- `Warehouse Movement` - units moved (native, kg, tonne), dimensions,
  entered-by, keyed to SKU / warehouse / date / batch.
- `Ledger Activity` - mass and cost impact by activity class
  (Recount, Adjustment, Movement).

**Dimensions**
- `Item Catalog` - SKU code, category/class, item description, base measure.
- `Calendar` - calendar and reporting-period attributes.
- `Warehouse` - warehouse key, code/name, business unit.
- `Batch Registry` - supplier batch ref, grade code, status code.
- `Reporting Period` - period boundaries used for period slicers.

**Parameters & refresh**
- Standard incremental-refresh range parameters drive partition-based refresh
  on the large fact tables (only recent partitions reprocess).
- A history start parameter limits how far back the model loads.
- The model is **published to the workspace once** and reused: reports connect
  live to the shared semantic model rather than embedding their own copies -
  one version of business rules and measures for all reports.

## Reports (recreated as mockups)

**Warehouse Movement Detail**
- Slicers: reporting period, warehouse, SKU code.
- Detail grid: post date, SKU, batch ref, dimensions, category, doc ref,
  mass (kg), entered by.
- Drill-through pages: movement by SKU; record-level detail.

**Adjustment & Count Overview**
- KPI cards: net adjustments, recount gains, recount losses - shown both in
  mass (kg) and cost impact ($).
- Unit toggle (KG / Tonnes) implemented as a field parameter.
- Clustered bar chart: mass by warehouse and activity type.
- Warehouse quick-filter buttons and post-date range slicer.

## Why this design
A single governed semantic model with incremental refresh keeps report
performance high while guaranteeing every report shows identical, validated
numbers - the central goal of the migration.
