-- Test queries for Raptor.dbo.DimDate table via federated query

-- 1. Check table structure and sample data
SELECT TOP 10 *
FROM raptor_external.dbo.DimDate
LIMIT 10;

-- 2. Count total rows
SELECT COUNT(*) as total_rows
FROM raptor_external.dbo.DimDate;

-- 3. Get date range (adjust column names based on actual schema)
-- SELECT
--     MIN(date_key) as earliest_date,
--     MAX(date_key) as latest_date
-- FROM raptor_external.dbo.DimDate;

-- 4. Query for specific year/month
-- SELECT *
-- FROM raptor_external.dbo.DimDate
-- WHERE year = 2025 AND month = 12
-- LIMIT 100;

-- 5. Get distinct years
-- SELECT DISTINCT year
-- FROM raptor_external.dbo.DimDate
-- ORDER BY year DESC;
