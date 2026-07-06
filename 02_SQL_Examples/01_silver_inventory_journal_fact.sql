/* ============================================================================
   SILVER LAYER LOAD - Inventory Journal Transaction Fact
   ----------------------------------------------------------------------------
   ILLUSTRATIVE EXAMPLE - artificial lakehouse, schema, and value details.
   Mirrors the transformation pattern used in the capstone project:
   bronze D365 F&O tables (landed via Azure Synapse Link) are joined,
   filtered by posting type, and materialized as a curated silver Delta table.
   ============================================================================ */

-- Rebuild target table (full refresh pattern for demonstration)
DROP TABLE IF EXISTS MFG_ANALYTICS.silver.InventoryJournTrans;

CREATE TABLE MFG_ANALYTICS.silver.InventoryJournTrans
USING DELTA
AS
WITH stage AS (
    SELECT
        ma.MAINACCOUNTID,
        gje.SUBLEDGERVOUCHER,
        gje.ACCOUNTINGDATE,
        gjae.TRANSACTIONCURRENCYAMOUNT,
        gjae.POSTINGTYPE
    FROM mfg_prod.financeops.GeneralJourEntry            AS gje
    JOIN mfg_prod.financeops.GeneralJournalAccountEntry     AS gjae
         ON gjae.GeneralJourEntry = gje.RECID
    JOIN mfg_prod.financeops.DimensionAttributeValueCombination AS davc
         ON gjae.LEDGERDIMENSION     = davc.RECID
    JOIN mfg_prod.financeops.MainAccount                    AS ma
         ON davc.MAINACCOUNT         = ma.RECID
    WHERE gjae.POSTINGTYPE IN (93, 94)          -- inventory-related posting types
)
SELECT
    MAINACCOUNTID,
    SUBLEDGERVOUCHER,
    CAST(ACCOUNTINGDATE AS DATE)                       AS TransactionDate,
    SUM(TRANSACTIONCURRENCYAMOUNT)                     AS TransactionAmount,
    COUNT(*)                                           AS LineCount,
    current_timestamp()                                AS LoadTimestamp
FROM stage
GROUP BY MAINACCOUNTID, SUBLEDGERVOUCHER, CAST(ACCOUNTINGDATE AS DATE);


/* ============================================================================
   INCREMENTAL MERGE VARIANT
   Used for daily scheduled runs so only new/changed vouchers are processed.
   ============================================================================ */

MERGE INTO MFG_ANALYTICS.silver.InventoryJournTrans AS tgt
USING (
    SELECT
        ma.MAINACCOUNTID,
        gje.SUBLEDGERVOUCHER,
        CAST(gje.ACCOUNTINGDATE AS DATE)               AS TransactionDate,
        SUM(gjae.TRANSACTIONCURRENCYAMOUNT)            AS TransactionAmount,
        COUNT(*)                                       AS LineCount
    FROM mfg_prod.financeops.GeneralJourEntry            AS gje
    JOIN mfg_prod.financeops.GeneralJournalAccountEntry     AS gjae
         ON gjae.GeneralJourEntry = gje.RECID
    JOIN mfg_prod.financeops.DimensionAttributeValueCombination AS davc
         ON gjae.LEDGERDIMENSION     = davc.RECID
    JOIN mfg_prod.financeops.MainAccount                    AS ma
         ON davc.MAINACCOUNT         = ma.RECID
    WHERE gjae.POSTINGTYPE IN (93, 94)
      AND gje.MODIFIEDDATETIME >= date_sub(current_date(), 3)  -- rolling window
    GROUP BY ma.MAINACCOUNTID, gje.SUBLEDGERVOUCHER, CAST(gje.ACCOUNTINGDATE AS DATE)
) AS src
ON  tgt.MAINACCOUNTID    = src.MAINACCOUNTID
AND tgt.SUBLEDGERVOUCHER = src.SUBLEDGERVOUCHER
AND tgt.TransactionDate  = src.TransactionDate
WHEN MATCHED THEN UPDATE SET
    tgt.TransactionAmount = src.TransactionAmount,
    tgt.LineCount         = src.LineCount,
    tgt.LoadTimestamp     = current_timestamp()
WHEN NOT MATCHED THEN INSERT
    (MAINACCOUNTID, SUBLEDGERVOUCHER, TransactionDate, TransactionAmount, LineCount, LoadTimestamp)
VALUES
    (src.MAINACCOUNTID, src.SUBLEDGERVOUCHER, src.TransactionDate, src.TransactionAmount, src.LineCount, current_timestamp());
