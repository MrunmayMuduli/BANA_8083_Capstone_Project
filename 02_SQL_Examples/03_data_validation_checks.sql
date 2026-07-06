/* ============================================================================
   DATA QUALITY & VALIDATION CHECKS
   ----------------------------------------------------------------------------
   ILLUSTRATIVE EXAMPLE — artificial names. Run after each scheduled load to
   confirm migrated/curated data reconciles with source systems, protecting
   reporting accuracy during the migration.
   ============================================================================ */

-- 1. Row count reconciliation: bronze (Synapse Link) vs silver
SELECT
    'InventoryJournalTransaction_Fact' AS TableName,
    (SELECT COUNT(DISTINCT SUBLEDGERVOUCHER)
       FROM mfg_prod.finop.GeneralJournalEntry
      WHERE ACCOUNTINGDATE >= '2024-01-01')             AS BronzeVoucherCount,
    (SELECT COUNT(DISTINCT SUBLEDGERVOUCHER)
       FROM MFG_ANALYTICS.silver.InventoryJournalTransaction_Fact
      WHERE TransactionDate >= '2024-01-01')            AS SilverVoucherCount;

-- 2. Null checks on business keys
SELECT COUNT(*) AS NullKeyRows
FROM MFG_ANALYTICS.silver.InventoryJournalTransaction_Fact
WHERE MAINACCOUNTID IS NULL
   OR SUBLEDGERVOUCHER IS NULL
   OR TransactionDate IS NULL;

-- 3. Duplicate grain check (should return zero rows)
SELECT MAINACCOUNTID, SUBLEDGERVOUCHER, TransactionDate, COUNT(*) AS DupCount
FROM MFG_ANALYTICS.silver.InventoryJournalTransaction_Fact
GROUP BY MAINACCOUNTID, SUBLEDGERVOUCHER, TransactionDate
HAVING COUNT(*) > 1;

-- 4. Amount reconciliation vs legacy SQL Server report logic (tolerance $0.01)
WITH legacy AS (
    SELECT MainAccountId, SUM(Amount) AS LegacyAmount
    FROM   legacy_sqlserver.dbo.vw_InventoryJournalReport   -- copied reference extract
    GROUP BY MainAccountId
),
fabric AS (
    SELECT MAINACCOUNTID AS MainAccountId, SUM(TransactionAmount) AS FabricAmount
    FROM   MFG_ANALYTICS.silver.InventoryJournalTransaction_Fact
    GROUP BY MAINACCOUNTID
)
SELECT l.MainAccountId, l.LegacyAmount, f.FabricAmount,
       f.FabricAmount - l.LegacyAmount AS Variance
FROM legacy l
FULL OUTER JOIN fabric f ON f.MainAccountId = l.MainAccountId
WHERE ABS(COALESCE(f.FabricAmount,0) - COALESCE(l.LegacyAmount,0)) > 0.01;

-- 5. Freshness check: latest load must be within the last 26 hours
SELECT MAX(LoadTimestamp) AS LastLoad,
       CASE WHEN MAX(LoadTimestamp) < current_timestamp() - INTERVAL 26 HOURS
            THEN 'STALE — investigate pipeline run' ELSE 'OK' END AS FreshnessStatus
FROM MFG_ANALYTICS.silver.InventoryJournalTransaction_Fact;
