-- Test queries for Raptor.dbo.DimDate table via federated query

-- 1. Check table structure and sample data
-- Note: raptor_external maps to Raptor.dbo schema, so tables are directly accessible
SELECT *
FROM raptor_external.DimDate
LIMIT 10;

-- 2. Count total rows
SELECT COUNT(*) as total_rows
FROM raptor_external.DimDate;

-- 3. Get first and last rows to see date range
SELECT * FROM raptor_external.DimDate ORDER BY 1 LIMIT 1;
SELECT * FROM raptor_external.DimDate ORDER BY 1 DESC LIMIT 1;

-- 4. Query for specific year/month
-- SELECT *
-- FROM raptor_external.dbo.DimDate
-- WHERE year = 2025 AND month = 12
-- LIMIT 100;

-- 5. Get distinct years
-- SELECT DISTINCT year
-- FROM raptor_external.dbo.DimDate
-- ORDER BY year DESC;
