-- Test queries for Raptor.dbo.DimLocation table via federated query

-- 1. Check table structure and sample data
-- Note: raptor_external maps to Raptor.dbo schema, so tables are directly accessible
SELECT *
FROM raptor_external.DimLocation
LIMIT 10;

-- 2. Count total rows
SELECT COUNT(*) as total_rows
FROM raptor_external.DimLocation;

-- 3. Get column information (first 5 rows with all columns)
SELECT *
FROM raptor_external.DimLocation
LIMIT 5;

-- 4. Query with filter (example - adjust based on actual columns)
-- SELECT *
-- FROM raptor_external.dbo.DimLocation
-- WHERE location_type = 'specific_value'
-- LIMIT 100;

-- 5. Check for NULL values in key columns
-- SELECT
--     COUNT(*) as total_rows,
--     COUNT(location_id) as non_null_location_id,
--     COUNT(*) - COUNT(location_id) as null_location_id
-- FROM raptor_external.dbo.DimLocation;
