/* ============================================================================
   FINAL REPORTING (GOLD) LAYER — tables feeding Power BI
   ----------------------------------------------------------------------------
   ILLUSTRATIVE EXAMPLE — artificial names and logic shapes.

   Schema layout in the analytics lakehouse (recreated):
     silver_src  — silver-level tables copied directly from SQL Server
     gold_src    — gold-level tables copied directly from SQL Server
                   (both carry the legacy business logic)
     rpt_gold    — FINAL reporting tables built by notebooks; each combines
                   whatever mix of bronze (D365), silver_src, and gold_src
                   inputs the target report requires.
   ============================================================================ */

-- 1. Final reporting fact: inventory rollforward
--    Combines bronze D365 transactions + silver_src product + gold_src UOM logic
CREATE OR REPLACE TABLE MFG_ANALYTICS.rpt_gold.InventoryRollforward
USING DELTA
AS
SELECT
    t.ItemId                                   AS ItemNumber,
    t.InventSiteId                             AS InventorySiteKey,
    CAST(t.DatePhysical AS DATE)               AS DateKey,
    lt.TagKey,
    SUM(t.Qty)                                 AS InventoryQuantity,
    SUM(t.Qty * u.LbPerUnit)                   AS InventoryQuantityLb,
    SUM(t.Qty * u.LbPerUnit) / 2000.0          AS InventoryQuantityTon,
    MAX(t.PostedBy)                            AS PostedBy
FROM mfg_prod.finop.InventTrans                AS t   -- BRONZE (D365 via Synapse Link)
JOIN MFG_ANALYTICS.silver_src.Product          AS p   -- SILVER (copied from SQL Server)
     ON p.ItemNumber = t.ItemId
JOIN MFG_ANALYTICS.gold_src.vwUomConversion    AS u   -- GOLD legacy logic (SQL Server)
     ON u.ItemNumber = p.ItemNumber
LEFT JOIN MFG_ANALYTICS.silver_src.Lot         AS lt
     ON lt.TagNumber = t.TagId
GROUP BY t.ItemId, t.InventSiteId, CAST(t.DatePhysical AS DATE), lt.TagKey;


-- 2. Final reporting table: inventory journal summary
--    Built from the silver journal fact + gold_src fiscal period table
CREATE OR REPLACE TABLE MFG_ANALYTICS.rpt_gold.InventoryJournalSummary
USING DELTA
AS
SELECT
    j.InventorySiteKey,
    j.JournalType,                       -- 'Counting' | 'Inventory adjustment' | 'Movement'
    fp.FiscalPeriod,
    SUM(j.AdjustmentWeightLb)            AS AdjustmentWeightLb,
    SUM(j.AdjustmentCost)                AS AdjustmentCost
FROM MFG_ANALYTICS.silver_src.InventoryJournalTransaction_Fact AS j
JOIN MFG_ANALYTICS.gold_src.FiscalPeriod                       AS fp
     ON j.TransactionDate BETWEEN fp.PeriodStartDate AND fp.PeriodEndDate
GROUP BY j.InventorySiteKey, j.JournalType, fp.FiscalPeriod;


-- 3. Conformed date dimension exposed to the semantic model
CREATE OR REPLACE VIEW MFG_ANALYTICS.rpt_gold.vw_TransactionDate
AS
SELECT
    DateKey,
    CalendarDate,
    MONTH(CalendarDate)                       AS MonthOfYear,
    date_format(CalendarDate, 'MMM')          AS MonthAbbr,
    YEAR(CalendarDate)                        AS CalendarYear,
    CONCAT('FY', FiscalYear, '-P',
           LPAD(FiscalPeriod, 2, '0'))        AS Period
FROM MFG_ANALYTICS.silver_src.DateTable;

/* NOTE: the input mix (bronze vs silver_src vs gold_src) changes per report —
   each rpt_gold table is designed around what its target report needs.        */
