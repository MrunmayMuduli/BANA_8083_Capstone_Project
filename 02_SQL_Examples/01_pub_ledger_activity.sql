/* ============================================================================
   PUBLISHED LAYER BUILD - Ledger Activity Summary
   ----------------------------------------------------------------------------
   ILLUSTRATIVE EXAMPLE - fully fictional lakehouse, schema, table, and column
   names. Recreates only the transformation PATTERN used in the capstone
   project (staging joins across raw source tables, filter by category,
   materialize as a published reporting table). No names or identifiers here
   correspond to any real system.
   ============================================================================ */

-- Rebuild target table (full-refresh pattern for demonstration)
DROP TABLE IF EXISTS insights_lh.pub_reports.LedgerActivitySummary;

CREATE TABLE insights_lh.pub_reports.LedgerActivitySummary
USING DELTA
AS
WITH staged AS (
    SELECT
        al.GLCODE,
        fh.DOCREF,
        fh.POSTDATE,
        fd.AMOUNTLOCAL,
        fd.CATEGORYCODE
    FROM corelanding_lh.fin_ledger.FinEntryHeader   AS fh
    JOIN corelanding_lh.fin_ledger.FinEntryDetail   AS fd
         ON fd.HEADERREF = fh.ROWKEY
    JOIN corelanding_lh.fin_ledger.DimBridge        AS db
         ON fd.BRIDGEREF = db.ROWKEY
    JOIN corelanding_lh.fin_ledger.AccountLookup    AS al
         ON db.ACCOUNTREF = al.ROWKEY
    WHERE fd.CATEGORYCODE IN (7, 8)          -- warehouse-related categories
)
SELECT
    GLCODE,
    DOCREF,
    CAST(POSTDATE AS DATE)                             AS PostDate,
    SUM(AMOUNTLOCAL)                                   AS PostedAmount,
    COUNT(*)                                           AS DetailLines,
    current_timestamp()                                AS RefreshedAt
FROM staged
GROUP BY GLCODE, DOCREF, CAST(POSTDATE AS DATE);


/* ============================================================================
   INCREMENTAL MERGE VARIANT
   Used for daily scheduled runs so only new or changed documents reprocess.
   ============================================================================ */

MERGE INTO insights_lh.pub_reports.LedgerActivitySummary AS tgt
USING (
    SELECT
        al.GLCODE,
        fh.DOCREF,
        CAST(fh.POSTDATE AS DATE)                      AS PostDate,
        SUM(fd.AMOUNTLOCAL)                            AS PostedAmount,
        COUNT(*)                                        AS DetailLines
    FROM corelanding_lh.fin_ledger.FinEntryHeader      AS fh
    JOIN corelanding_lh.fin_ledger.FinEntryDetail      AS fd
         ON fd.HEADERREF = fh.ROWKEY
    JOIN corelanding_lh.fin_ledger.DimBridge           AS db
         ON fd.BRIDGEREF = db.ROWKEY
    JOIN corelanding_lh.fin_ledger.AccountLookup       AS al
         ON db.ACCOUNTREF = al.ROWKEY
    WHERE fd.CATEGORYCODE IN (7, 8)
      AND fh.CHANGESTAMP >= date_sub(current_date(), 3)   -- rolling window
    GROUP BY al.GLCODE, fh.DOCREF, CAST(fh.POSTDATE AS DATE)
) AS src
ON  tgt.GLCODE   = src.GLCODE
AND tgt.DOCREF   = src.DOCREF
AND tgt.PostDate = src.PostDate
WHEN MATCHED THEN UPDATE SET
    tgt.PostedAmount = src.PostedAmount,
    tgt.DetailLines  = src.DetailLines,
    tgt.RefreshedAt  = current_timestamp()
WHEN NOT MATCHED THEN INSERT
    (GLCODE, DOCREF, PostDate, PostedAmount, DetailLines, RefreshedAt)
VALUES
    (src.GLCODE, src.DOCREF, src.PostDate, src.PostedAmount, src.DetailLines, current_timestamp());
