#!/usr/bin/env python3
"""
Create external schema in Redshift for MSSQL database federation
"""

import boto3
import json
import psycopg2
import sys
import os

AWS_PROFILE = os.environ.get('AWS_PROFILE', '459286107047_svc_data_prod')
AWS_REGION = 'us-west-2'

# Terraform outputs
REDSHIFT_ENDPOINT = "redshift-fed-prod-workgroup.459286107047.us-west-2.redshift-serverless.amazonaws.com"
REDSHIFT_PORT = 5439
REDSHIFT_DATABASE = "dev"
REDSHIFT_ADMIN_SECRET_ARN = "arn:aws:secretsmanager:us-west-2:459286107047:secret:redshift-fed-prod-redshift-admin-20251205060308579300000001-ufJv9W"
REDSHIFT_IAM_ROLE_ARN = "arn:aws:iam::459286107047:role/redshift-fed-prod-redshift-role"
MSSQL_SECRET_ARN = "arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux"

# MSSQL configuration
MSSQL_HOST = "LSNRGNP04A.ad.idelb.com"
MSSQL_PORT = 4070
MSSQL_DATABASE = "Raptor"

def get_secret(secret_arn):
    """Retrieve secret from AWS Secrets Manager"""
    print(f"Retrieving secret: {secret_arn}")
    session = boto3.Session(profile_name=AWS_PROFILE, region_name=AWS_REGION)
    client = session.client('secretsmanager')

    try:
        response = client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(response['SecretString'])
        return secret
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        sys.exit(1)

def connect_to_redshift():
    """Connect to Redshift using admin credentials"""
    print(f"Connecting to Redshift: {REDSHIFT_ENDPOINT}:{REDSHIFT_PORT}/{REDSHIFT_DATABASE}")

    # Get Redshift admin credentials
    admin_secret = get_secret(REDSHIFT_ADMIN_SECRET_ARN)

    try:
        conn = psycopg2.connect(
            host=REDSHIFT_ENDPOINT,
            port=REDSHIFT_PORT,
            database=REDSHIFT_DATABASE,
            user=admin_secret['username'],
            password=admin_secret['password']
        )
        print("✓ Connected to Redshift")
        return conn
    except Exception as e:
        print(f"Error connecting to Redshift: {e}")
        sys.exit(1)

def create_external_schema(conn):
    """Create external schema for MSSQL database"""
    print(f"\nCreating external schema for {MSSQL_DATABASE}...")

    schema_name = "raptor_external"

    create_schema_sql = f"""
    CREATE EXTERNAL SCHEMA IF NOT EXISTS {schema_name}
    FROM SQLSERVER
    DATABASE '{MSSQL_DATABASE}' SCHEMA 'dbo'
    URI '{MSSQL_HOST}' PORT {MSSQL_PORT}
    IAM_ROLE '{REDSHIFT_IAM_ROLE_ARN}'
    SECRET_ARN '{MSSQL_SECRET_ARN}';
    """

    try:
        cursor = conn.cursor()
        cursor.execute(create_schema_sql)
        conn.commit()
        print(f"✓ External schema '{schema_name}' created successfully")
        cursor.close()
    except Exception as e:
        print(f"Error creating external schema: {e}")
        conn.rollback()
        return False

    return True

def verify_external_schema(conn):
    """Verify external schema was created"""
    print("\nVerifying external schema...")

    verify_sql = """
    SELECT schemaname, databasename, esoptions
    FROM svv_external_schemas
    WHERE schemaname = 'raptor_external';
    """

    try:
        cursor = conn.cursor()
        cursor.execute(verify_sql)
        results = cursor.fetchall()

        if results:
            print("✓ External schema verified:")
            for row in results:
                print(f"  Schema: {row[0]}, Database: {row[1]}")
        else:
            print("✗ External schema not found")
            return False

        cursor.close()
    except Exception as e:
        print(f"Error verifying external schema: {e}")
        return False

    return True

def list_external_tables(conn):
    """List tables available in the external schema"""
    print("\nListing tables in external schema...")

    list_tables_sql = """
    SELECT DISTINCT tablename
    FROM svv_external_tables
    WHERE schemaname = 'raptor_external'
    ORDER BY tablename;
    """

    try:
        cursor = conn.cursor()
        cursor.execute(list_tables_sql)
        results = cursor.fetchall()

        print(f"✓ Found {len(results)} tables:")
        for row in results:
            print(f"  - {row[0]}")

        cursor.close()
        return [row[0] for row in results]
    except Exception as e:
        print(f"Error listing external tables: {e}")
        return []

def test_table_query(conn, table_name):
    """Test querying a specific table"""
    print(f"\nTesting query on raptor_external.dbo.{table_name}...")

    test_sql = f"""
    SELECT COUNT(*) as row_count
    FROM raptor_external.dbo.{table_name};
    """

    try:
        cursor = conn.cursor()
        cursor.execute(test_sql)
        result = cursor.fetchone()
        print(f"✓ Table {table_name} has {result[0]} rows")
        cursor.close()
        return True
    except Exception as e:
        print(f"✗ Error querying table {table_name}: {e}")
        return False

def main():
    """Main function"""
    print("="*80)
    print("Creating External Schema for MSSQL Federation")
    print("="*80)
    print(f"AWS Profile: {AWS_PROFILE}")
    print(f"Redshift: {REDSHIFT_ENDPOINT}:{REDSHIFT_PORT}")
    print(f"MSSQL: {MSSQL_HOST}:{MSSQL_PORT}/{MSSQL_DATABASE}")
    print("")

    # Connect to Redshift
    conn = connect_to_redshift()

    # Create external schema
    if not create_external_schema(conn):
        conn.close()
        sys.exit(1)

    # Verify external schema
    if not verify_external_schema(conn):
        conn.close()
        sys.exit(1)

    # List external tables
    tables = list_external_tables(conn)

    # Test specific tables
    target_tables = ['DimLocation', 'DimDate']
    print(f"\nTesting target tables: {', '.join(target_tables)}")

    for table in target_tables:
        if table in tables:
            test_table_query(conn, table)
        else:
            print(f"✗ Table {table} not found in external schema")

    # Close connection
    conn.close()

    print("\n" + "="*80)
    print("✓ External schema setup complete!")
    print("="*80)
    print("\nYou can now query the tables using:")
    print(f"  SELECT * FROM raptor_external.dbo.DimLocation LIMIT 10;")
    print(f"  SELECT * FROM raptor_external.dbo.DimDate LIMIT 10;")
    print("")

if __name__ == "__main__":
    main()
