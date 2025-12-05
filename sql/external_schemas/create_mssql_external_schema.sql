-- Create external schema for MSSQL Raptor database
-- This allows Redshift to query tables in the MSSQL database without data movement

CREATE EXTERNAL SCHEMA IF NOT EXISTS raptor_external
FROM SQLSERVER
DATABASE 'Raptor'
URI 'LSNRGNP04A.ad.idelb.com' PORT 4070
IAM_ROLE '${redshift_iam_role_arn}'
SECRET_ARN 'arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux';

-- Verify external schema creation
SELECT * FROM svv_external_schemas WHERE schemaname = 'raptor_external';

-- List all tables in the external schema
SELECT DISTINCT tablename
FROM svv_external_tables
WHERE schemaname = 'raptor_external'
ORDER BY tablename;
