-- Create external schema for MSSQL Raptor database
-- This allows Redshift to query tables in the MSSQL database without data movement

-- Note: For SQL Server federated queries, you must specify both DATABASE and SCHEMA
CREATE EXTERNAL SCHEMA IF NOT EXISTS raptor_external
FROM SQLSERVER
DATABASE 'Raptor' SCHEMA 'dbo'
URI 'LSNRGNP04A.ad.idelb.com' PORT 4070
IAM_ROLE 'arn:aws:iam::459286107047:role/redshift-fed-prod-redshift-role'
SECRET_ARN 'arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux';

-- Verify external schema creation
SELECT * FROM svv_external_schemas WHERE schemaname = 'raptor_external';

-- List all tables in the external schema
SELECT DISTINCT tablename
FROM svv_external_tables
WHERE schemaname = 'raptor_external'
ORDER BY tablename;