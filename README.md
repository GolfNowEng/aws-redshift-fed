# AWS Redshift Federated Query & Zero-ETL Integration

Zero-ETL data integration solution from self-managed MSSQL databases to Amazon Redshift using federated queries. Enables real-time analytics without traditional ETL pipelines.

## Overview

This project implements federated queries from Amazon Redshift to self-managed MSSQL databases, enabling direct querying of operational data without data movement or traditional ETL pipelines.

**AWS Profile:** `459286107047_svc_data_prod`

## Architecture

```
[Self-Managed MSSQL] <--Federated Query--> [Amazon Redshift Serverless] --> [Analytics/BI Tools]
  LSNRGNP04A.ad.idelb.com:4070                    VPC: vpc-0e47374708b217ada
```

## Key Features

- **Federated Queries**: Query external MSSQL databases directly from Redshift
- **Zero Data Movement**: No data duplication, always current data
- **Unified Analytics**: Single interface for both local and external data
- **Secure Connectivity**: VPC networking with Secrets Manager for credentials
- **Performance Optimization**: Materialized views, query pushdown, WLM configuration

## Infrastructure Components

- **Amazon Redshift Serverless**: Analytics data warehouse
- **VPC**: `vpc-0e47374708b217ada`
- **Security Group**: `sg-08dff1d69f471a135`
- **Subnets**: `subnet-0f985b2a39b8e7094`, `subnet-02cb1a70c7d797105`
- **Secrets Manager**: `gndataeng/prod/db-mssql/raptor/analytics`
- **Source Database**: MSSQL at `LSNRGNP04A.ad.idelb.com:4070`

## Project Structure

```
aws-redshift-fed/
├── PROJECT_SPEC.md           # Comprehensive project specification
├── README.md                 # This file
├── terraform/                # Infrastructure as Code
│   ├── modules/
│   │   ├── redshift/        # Redshift serverless configuration
│   │   ├── iam/             # IAM roles and policies
│   │   ├── networking/      # VPC, security groups
│   │   ├── secrets/         # Secrets Manager configuration
│   │   └── monitoring/      # CloudWatch dashboards and alarms
│   └── environments/
│       └── prod/            # Production environment configuration
├── scripts/                  # Deployment and utility scripts
│   ├── create_jira_tickets.py
│   └── README.md
├── sql/                      # SQL scripts for views and schemas
│   ├── external_schemas/    # External schema definitions
│   ├── views/               # Standard views
│   ├── materialized_views/  # Materialized view definitions
│   └── stored_procedures/   # Stored procedure scripts
└── docs/                     # Documentation
    ├── architecture/        # Architecture diagrams
    ├── operations/          # Operations runbooks
    └── troubleshooting/     # Troubleshooting guides
```

## Quick Start

### Prerequisites

- AWS CLI configured with profile `459286107047_svc_data_prod`
- Terraform >= 1.0
- Python 3.9+
- Network access to MSSQL database

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/GolfNowEng/aws-redshift-fed.git
   cd aws-redshift-fed
   ```

2. **Configure AWS credentials:**
   ```bash
   export AWS_PROFILE=459286107047_svc_data_prod
   aws sts get-caller-identity
   ```

3. **Initialize Terraform:**
   ```bash
   cd terraform/environments/prod
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Deploy infrastructure:**
   ```bash
   terraform apply
   ```

## Usage

### Creating External Schema

```sql
CREATE EXTERNAL SCHEMA external_mssql
FROM SQLSERVER
DATABASE 'raptor'
URI 'LSNRGNP04A.ad.idelb.com' PORT 4070
IAM_ROLE 'arn:aws:iam::459286107047:role/redshift-federated-query-role'
SECRET_ARN 'arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux';
```

### Querying External Data

```sql
-- Query external table
SELECT * FROM external_mssql.dbo.your_table LIMIT 10;

-- Join local and external data
SELECT
    local.customer_id,
    local.customer_name,
    external.order_count
FROM
    local_schema.customers local
    INNER JOIN external_mssql.dbo.orders external
        ON local.customer_id = external.customer_id;
```

## Implementation Phases

This project follows an 8-phase implementation plan:

1. **Phase 1**: Foundation Setup (31h)
2. **Phase 2**: Federated Query Implementation (25h)
3. **Phase 3**: Query Optimization (30h)
4. **Phase 4**: Hybrid Data Integration (48h)
5. **Phase 5**: Security & Governance (32h)
6. **Phase 6**: Monitoring & Operations (37h)
7. **Phase 7**: Testing & Validation (56h)
8. **Phase 8**: Production Deployment (72h)

**Total Estimated Effort**: 331 hours (~8-9 weeks)

See [PROJECT_SPEC.md](PROJECT_SPEC.md) for detailed phase descriptions.

## Monitoring

- **CloudWatch Dashboards**: Monitor Redshift performance and query metrics
- **CloudWatch Alarms**: Alerts for failures, performance degradation, and capacity issues
- **Audit Logging**: User activity logs stored in S3

## Security

- **VPC Isolation**: Redshift deployed in private subnets
- **Secrets Manager**: Database credentials stored securely
- **IAM Roles**: Least-privilege access policies
- **Encryption**: At rest (KMS) and in transit (TLS)
- **Audit Logging**: CloudTrail for API calls, Redshift audit logs for queries

## Cost Estimation

**Monthly Production Costs** (Estimated):
- Redshift Serverless: $200-500 (usage-based)
- Secrets Manager: $0.40 per secret
- CloudWatch: $10-20 (logs and metrics)
- Data Transfer: Minimal (VPC to VPC)

**Total**: ~$300-800/month

## Jira Epic

**Epic**: [OPS-49969](https://golfnow.atlassian.net/browse/OPS-49969)

All project tasks are tracked in Jira with 8 stories covering the complete implementation.

## Documentation

- [PROJECT_SPEC.md](PROJECT_SPEC.md) - Comprehensive project specification
- [Architecture Documentation](docs/architecture/) - Architecture diagrams and design decisions
- [Operations Guide](docs/operations/) - Runbooks and procedures
- [Troubleshooting Guide](docs/troubleshooting/) - Common issues and solutions

## Support

For questions or issues:
- Create an issue in this repository
- Contact the Data Engineering team
- Slack: #data-engineering

## License

Internal use only - GolfNow/NBC Sports

---

**Last Updated**: 2025-12-05
**Project Lead**: Data Engineering Team
**Status**: Planning Phase
