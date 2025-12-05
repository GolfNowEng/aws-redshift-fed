-- Performance testing queries for federated queries

-- 1. Check query execution plan for DimLocation
EXPLAIN
SELECT * FROM raptor_external.dbo.DimLocation LIMIT 100;

-- 2. Check query execution plan for DimDate
EXPLAIN
SELECT * FROM raptor_external.dbo.DimDate LIMIT 100;

-- 3. Test join between the two external tables (adjust join columns based on schema)
-- EXPLAIN
-- SELECT
--     l.*,
--     d.*
-- FROM raptor_external.dbo.DimLocation l
-- JOIN raptor_external.dbo.DimDate d
--     ON l.date_key = d.date_key
-- LIMIT 100;

-- 4. Query to check pushdown optimization
-- Look for "pushdown" in the explain plan
SELECT * FROM raptor_external.dbo.DimLocation WHERE 1=1 LIMIT 10;

-- 5. Monitor federated query performance
SELECT
    query,
    userid,
    starttime,
    endtime,
    DATEDIFF(seconds, starttime, endtime) as duration_seconds,
    external_table_count
FROM
    svl_qlog
WHERE
    external_table_count > 0
ORDER BY
    starttime DESC
LIMIT 20;
