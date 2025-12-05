# Architecture - AWS DMS Zero-ETL Integration to Redshift

## Overview

This project uses **AWS Database Migration Service (DMS)** to implement Zero-ETL integration from a self-managed SQL Server database to Amazon Redshift. This approach enables continuous data replication without building custom ETL pipelines.

## Architecture Pattern: DMS Zero-ETL

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS Account (459286107047)                    │
│                                                                       │
│  ┌────────────────────┐          ┌──────────────────────┐          │
│  │  Self-Managed      │          │   AWS DMS            │          │
│  │  SQL Server        │◄────────►│   Replication        │          │
│  │                    │  Extract │   Instance           │          │
│  │  LSNRGNP04A:4070  │          │                      │          │
│  │  Database: Raptor  │          │   ┌──────────────┐  │          │
│  │  - DimLocation     │          │   │ CDC Engine   │  │          │
│  │  - DimDate         │          │   │ Full Load    │  │          │
│  └────────────────────┘          │   │ Incremental  │  │          │
│                                   │   └──────────────┘  │          │
│                                   └──────────┬───────────┘          │
│                                              │ Load                 │
│                                              ▼                      │
│                            ┌────────────────────────────┐          │
│                            │  Amazon Redshift           │          │
│                            │  Serverless                │          │
│                            │                            │          │
│                            │  Namespace: redshift-fed-  │          │
│                            │  Database: dev             │          │
│                            │  Schema: public            │          │
│                            │  - dimlocation             │          │
│                            │  - dimdate                 │          │
│                            └────────────────────────────┘          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Why DMS Zero-ETL?

### Problem: Federated Queries Not Supported
- Redshift federated queries only support PostgreSQL and MySQL
- Cannot directly query SQL Server databases
- Need alternative for MSSQL sources

### Solution: DMS Zero-ETL Integration
- **Continuous replication** from SQL Server to Redshift
- **Change Data Capture (CDC)** for near real-time updates
- **Managed service** - no custom ETL code
- **Scalable** - handles large data volumes
- **Minimal impact** on source database

## Components

### 1. Source: Self-Managed SQL Server
- **Host**: LSNRGNP04A.ad.idelb.com
- **Port**: 4070
- **Database**: Raptor
- **Schema**: dbo
- **Tables**: DimLocation, DimDate
- **Authentication**: SQL Server authentication via Secrets Manager
- **Requirements**: SQL Server Agent running, CDC enabled

### 2. AWS DMS Replication Instance
- **Type**: dms.t3.medium (recommended for small workloads)
- **VPC**: vpc-0e47374708b217ada
- **Subnets**: subnet-0f985b2a39b8e7094, subnet-02cb1a70c7d797105
- **Security Group**: sg-08dff1d69f471a135
- **Multi-AZ**: Optional (recommended for production)
- **Storage**: 100 GB (auto-expandable)

### 3. DMS Endpoints

#### Source Endpoint (SQL Server)
- **Engine**: sqlserver
- **Server**: LSNRGNP04A.ad.idelb.com
- **Port**: 4070
- **Database**: Raptor
- **Authentication**: Secrets Manager
- **SSL Mode**: none (internal network)
- **Extra Connection Attributes**:
  ```
  readBackupOnly=Y;safeguardPolicy=EXCLUSIVE_AUTOMATIC_TRUNCATION
  ```

#### Target Endpoint (Redshift)
- **Engine**: redshift
- **Server**: redshift-fed-prod-workgroup.459286107047.us-west-2.redshift-serverless.amazonaws.com
- **Port**: 5439
- **Database**: dev
- **Schema**: public
- **Authentication**: Secrets Manager
- **Settings**:
  - acceptAnyDate: true
  - truncateColumns: false
  - writeBufferSize: 32768

### 4. DMS Replication Tasks

#### Task Configuration
- **Migration Type**: full-load-and-cdc
- **Target Table Preparation**: drop-and-create or truncate-before-load
- **Include LOB Columns**: limited (max size: 32 KB)
- **Enable Validation**: Yes
- **Enable CloudWatch Logs**: Yes

#### Table Mappings
```json
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "include-dimlocation",
      "object-locator": {
        "schema-name": "dbo",
        "table-name": "DimLocation"
      },
      "rule-action": "include"
    },
    {
      "rule-type": "selection",
      "rule-id": "2",
      "rule-name": "include-dimdate",
      "object-locator": {
        "schema-name": "dbo",
        "table-name": "DimDate"
      },
      "rule-action": "include"
    },
    {
      "rule-type": "transformation",
      "rule-id": "3",
      "rule-name": "lowercase-tables",
      "rule-target": "table",
      "object-locator": {
        "schema-name": "dbo",
        "table-name": "%"
      },
      "rule-action": "convert-lowercase"
    }
  ]
}
```

### 5. Amazon Redshift Target
- **Namespace**: redshift-fed-prod
- **Database**: dev
- **Schema**: public
- **Tables**:
  - `dimlocation` (lowercase, auto-created by DMS)
  - `dimdate` (lowercase, auto-created by DMS)
- **IAM Role**: redshift-fed-prod-redshift-role

## Data Flow

### Phase 1: Full Load
1. DMS connects to SQL Server source
2. Reads DimLocation and DimDate tables
3. Creates tables in Redshift (schema auto-generated)
4. Bulk loads all existing rows
5. Validates row counts

### Phase 2: Change Data Capture (CDC)
1. DMS monitors SQL Server transaction log
2. Captures INSERT, UPDATE, DELETE operations
3. Applies changes to Redshift in near real-time
4. Maintains data consistency
5. Handles retries and error recovery

## Network Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                  VPC: vpc-0e47374708b217ada                   │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Security Group: sg-08dff1d69f471a135               │    │
│  │                                                       │    │
│  │  Ingress Rules:                                      │    │
│  │  - Port 5439 (Redshift) from VPC CIDR               │    │
│  │  - Port 1433 (SQL Server) from VPC CIDR             │    │
│  │                                                       │    │
│  │  Egress Rules:                                       │    │
│  │  - Port 4070 to LSNRGNP04A.ad.idelb.com            │    │
│  │  - Port 5439 to Redshift endpoint                   │    │
│  │  - Port 443 for AWS APIs                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                                │
│  ┌─────────────┐      ┌──────────────┐      ┌───────────┐   │
│  │ Subnet      │      │   Subnet     │      │  DMS      │   │
│  │ us-west-2a  │      │  us-west-2b  │      │ Repl.     │   │
│  │ (private)   │      │  (private)   │      │ Instance  │   │
│  └─────────────┘      └──────────────┘      └───────────┘   │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

## Monitoring & Operations

### CloudWatch Metrics
- **DMS Task Metrics**:
  - FullLoadThroughputRowsSource
  - FullLoadThroughputRowsTarget
  - CDCLatencySource
  - CDCLatencyTarget
  - CDCIncomingChanges

- **Redshift Metrics**:
  - DatabaseConnections
  - CPUUtilization
  - PercentageDiskSpaceUsed

### CloudWatch Logs
- DMS task logs: `/aws/dms/tasks/<task-id>`
- Redshift logs: `/aws/redshift/redshift-fed-prod`

### Validation
- DMS validation compares source and target row counts
- Validates data integrity during replication
- Reports mismatches in CloudWatch logs

## Cost Estimation

### Monthly Costs
- **DMS Replication Instance** (dms.t3.medium):
  - On-Demand: ~$146/month
  - Reserved (1-year): ~$87/month

- **DMS Data Transfer**:
  - VPC to VPC: Free
  - If crossing AZs: $0.01/GB

- **Redshift Serverless**: $200-500/month (unchanged)

- **CloudWatch Logs**: $5-10/month

- **Secrets Manager**: $0.80/month (2 secrets)

**Total Estimated Cost**: ~$352-657/month

## Security

### Data Encryption
- **In Transit**: TLS 1.2 for all connections
- **At Rest**:
  - Redshift: AES-256 encryption
  - DMS: EBS volume encryption

### Access Control
- **IAM Roles**: Least-privilege policies
- **Secrets Manager**: Credentials rotation enabled
- **VPC Isolation**: Private subnets only
- **Security Groups**: Restricted ingress/egress

### Compliance
- **Audit Logging**: All operations logged to CloudWatch
- **Encryption**: FIPS 140-2 compliant
- **Network Security**: No public internet exposure

## Advantages Over Traditional ETL

1. **No Code Required**: Fully managed service
2. **Continuous Replication**: Near real-time updates via CDC
3. **Automatic Schema Evolution**: Handles schema changes
4. **Built-in Monitoring**: CloudWatch integration
5. **High Availability**: Multi-AZ option
6. **Scalable**: Handles GB to TB datasets
7. **Minimal Source Impact**: Reads from transaction log

## Limitations

1. **Initial Full Load**: Can take time for large tables
2. **CDC Lag**: Usually <1 minute but can vary
3. **Schema Changes**: Some DDL operations require task restart
4. **Unsupported Data Types**: Some SQL Server types may need transformation
5. **Cost**: DMS instance runs continuously

## Next Steps

1. Enable CDC on SQL Server source database
2. Deploy DMS infrastructure via Terraform
3. Create and configure DMS endpoints
4. Set up replication task with table mappings
5. Start full load and enable CDC
6. Validate data consistency
7. Monitor replication lag and performance

---

**References:**
- [AWS DMS Zero-ETL Blog Post](https://aws.amazon.com/blogs/database/simplify-data-integration-using-zero-etl-from-self-managed-databases-to-amazon-redshift/)
- [AWS DMS Documentation](https://docs.aws.amazon.com/dms/)
- [AWS DMS SQL Server Source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html)
- [AWS DMS Redshift Target](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.Redshift.html)
