/* ============================================================================
   PUBLISHED REPORTING TABLES - feeding Power BI
   ----------------------------------------------------------------------------
   ILLUSTRATIVE EXAMPLE - fully fictional names throughout.

   Schema layout in the analytics lakehouse (recreated):
     import_stage - tables copied directly from a historical database
     import_ref   - reference/lookup tables copied from the same database
                    (carries pre-migration business rules)
     pub_reports  - the FINAL published tables built by notebooks; each one
                    combines whatever mix of raw, import_stage, and import_ref
                    inputs the target report requires - the mix varies by report.
   ============================================================================ */

-- 1. Published fact: warehouse movement summary
--    Combines raw movement data + staged item catalog + reference measure logic
CREATE OR REPLACE TABLE insights_lh.pub_reports.WarehouseMovementSummary
USING DELTA
AS
SELECT
    ml.SKUCODE,
    ml.WAREHOUSECODE                            AS WarehouseKey,
    CAST(ml.MOVEDATE AS DATE)                   AS DateKey,
    br.BatchKey,
    SUM(ml.UNITSMOVED)                          AS UnitsMoved,
    SUM(ml.UNITSMOVED * mf.KgPerUnit)            AS MassKg,
    SUM(ml.UNITSMOVED * mf.KgPerUnit) / 1000.0   AS MassTonnes,
    MAX(ml.ENTEREDBY)                           AS EnteredBy
FROM corelanding_lh.wh_ops.MovementLog          AS ml    -- RAW (exported feed)
JOIN insights_lh.import_stage.ItemCatalog       AS ic    -- copied from hist. DB
     ON ic.SKUCODE = ml.SKUCODE
JOIN insights_lh.import_ref.MeasureFactors      AS mf    -- reference rules
     ON mf.SKUCODE = ic.SKUCODE
LEFT JOIN insights_lh.import_stage.BatchRegistry AS br
     ON br.BATCHREF = ml.BATCHREF
GROUP BY ml.SKUCODE, ml.WAREHOUSECODE, CAST(ml.MOVEDATE AS DATE), br.BatchKey;


-- 2. Published table: adjustment and count overview
--    Built from the published activity fact + reference period table
CREATE OR REPLACE TABLE insights_lh.pub_reports.AdjustmentOverview
USING DELTA
AS
SELECT
    a.WarehouseKey,
    a.ActivityClass,                     -- 'Recount' | 'Adjustment' | 'Movement'
    rp.PeriodLabel,
    SUM(a.MassKg)                        AS MassKg,
    SUM(a.CostImpact)                    AS CostImpact
FROM insights_lh.pub_reports.LedgerActivitySummaryDetail AS a
JOIN insights_lh.import_ref.PeriodTable                  AS rp
     ON a.PostDate BETWEEN rp.PeriodStart AND rp.PeriodEnd
GROUP BY a.WarehouseKey, a.ActivityClass, rp.PeriodLabel;


-- 3. Conformed calendar exposed to the semantic model
CREATE OR REPLACE VIEW insights_lh.pub_reports.vw_Calendar
AS
SELECT
    DateKey,
    CalendarDate,
    MONTH(CalendarDate)                       AS MonthOfYear,
    date_format(CalendarDate, 'MMM')          AS MonthAbbr,
    YEAR(CalendarDate)                        AS CalendarYear,
    CONCAT('Y', ReportingYear, '-P',
           LPAD(ReportingPeriod, 2, '0'))      AS PeriodLabel
FROM insights_lh.import_stage.CalendarSeed;

/* NOTE: the input mix (raw vs import_stage vs import_ref) changes per report -
   each pub_reports table is designed around what its target report needs. */
