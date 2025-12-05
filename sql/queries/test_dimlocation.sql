-- Test queries for Raptor.dbo.DimLocation table via federated query

-- 1. Check table structure and sample data
SELECT TOP 10 *
FROM raptor_external.dbo.DimLocation
LIMIT 10;

-- 2. Count total rows
SELECT COUNT(*) as total_rows
FROM raptor_external.dbo.DimLocation;

-- 3. Get distinct location types (if column exists)
-- Adjust column names based on actual schema
SELECT
    COUNT(DISTINCT location_id) as unique_locations
FROM raptor_external.dbo.DimLocation;

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
