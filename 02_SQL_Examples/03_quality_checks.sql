/* ============================================================================
   DATA QUALITY & VALIDATION CHECKS
   ----------------------------------------------------------------------------
   ILLUSTRATIVE EXAMPLE - fully fictional names. Run after each scheduled load
   to confirm migrated and published data reconciles with source systems,
   protecting reporting accuracy during the migration.
   ============================================================================ */

-- 1. Row count reconciliation: raw export vs published layer
SELECT
    'LedgerActivitySummary' AS TableName,
    (SELECT COUNT(DISTINCT DOCREF)
       FROM corelanding_lh.fin_ledger.FinEntryHeader
      WHERE POSTDATE >= '2024-01-01')                        AS RawDocCount,
    (SELECT COUNT(DISTINCT DOCREF)
       FROM insights_lh.pub_reports.LedgerActivitySummary
      WHERE PostDate >= '2024-01-01')                        AS PublishedDocCount;

-- 2. Null checks on business keys
SELECT COUNT(*) AS NullKeyRows
FROM insights_lh.pub_reports.LedgerActivitySummary
WHERE GLCODE IS NULL
   OR DOCREF IS NULL
   OR PostDate IS NULL;

-- 3. Duplicate grain check (should return zero rows)
SELECT GLCODE, DOCREF, PostDate, COUNT(*) AS DupCount
FROM insights_lh.pub_reports.LedgerActivitySummary
GROUP BY GLCODE, DOCREF, PostDate
HAVING COUNT(*) > 1;

-- 4. Amount reconciliation vs historical reporting logic (tolerance 0.01)
WITH hist AS (
    SELECT GlCode, SUM(Amount) AS HistAmount
    FROM   histops_db.dbo.vw_HistLedgerReport   -- copied reference extract
    GROUP BY GlCode
),
curr AS (
    SELECT GLCODE AS GlCode, SUM(PostedAmount) AS CurrAmount
    FROM   insights_lh.pub_reports.LedgerActivitySummary
    GROUP BY GLCODE
)
SELECT h.GlCode, h.HistAmount, c.CurrAmount,
       c.CurrAmount - h.HistAmount AS Variance
FROM hist h
FULL OUTER JOIN curr c ON c.GlCode = h.GlCode
WHERE ABS(COALESCE(c.CurrAmount,0) - COALESCE(h.HistAmount,0)) > 0.01;

-- 5. Freshness check: latest load must be within the last 26 hours
SELECT MAX(RefreshedAt) AS LastLoad,
       CASE WHEN MAX(RefreshedAt) < current_timestamp() - INTERVAL 26 HOURS
            THEN 'STALE - investigate pipeline run' ELSE 'OK' END AS FreshnessStatus
FROM insights_lh.pub_reports.LedgerActivitySummary;
