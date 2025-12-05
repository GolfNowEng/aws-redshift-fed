# Deployment Guide - AWS Redshift Federated Query

## Deployment Summary

**Date**: 2025-12-05
**AWS Profile**: `459286107047_svc_data_prod`
**Region**: us-west-2
**Status**: Phase 1 Complete ✓

## Infrastructure Deployed

### 1. Terraform Backend
- **S3 Bucket**: `gndataeng-terraform-state-prod`
  - Versioning: Enabled
  - Encryption: AES256
  - Public Access: Blocked
- **DynamoDB Table**: `gndataeng-terraform-lock-prod`
  - Billing Mode: PAY_PER_REQUEST

### 2. IAM Resources
- **Role**: `redshift-fed-prod-redshift-role`
  - ARN: `arn:aws:iam::459286107047:role/redshift-fed-prod-redshift-role`
  - Policies:
    - Secrets Manager access (MSSQL credentials)
    - S3 access (logging)
    - CloudWatch Logs access
    - Glue Data Catalog access

### 3. Redshift Serverless
- **Namespace**: `redshift-fed-prod`
  - Database: `dev`
  - Admin Username: `admin`
  - Admin Secret: `arn:aws:secretsmanager:us-west-2:459286107047:secret:redshift-fed-prod-redshift-admin-20251205060308579300000001-ufJv9W`

- **Workgroup**: `redshift-fed-prod-workgroup`
  - Endpoint: `redshift-fed-prod-workgroup.459286107047.us-west-2.redshift-serverless.amazonaws.com`
  - Port: `5439`
  - Base Capacity: 32 RPUs
  - VPC: `vpc-0e47374708b217ada`
  - Subnets: `subnet-0f985b2a39b8e7094`, `subnet-02cb1a70c7d797105`
  - Security Group: `sg-08dff1d69f471a135`
  - Publicly Accessible: No

### 4. Logging
- **CloudWatch Log Group**: `/aws/redshift/redshift-fed-prod`
  - Retention: 7 days
  - Log Exports: userlog, connectionlog, useractivitylog

## MSSQL Source Configuration

- **Host**: `LSNRGNP04A.ad.idelb.com`
- **Port**: `4070`
- **Database**: `Raptor`
- **Secret**: `arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux`
- **Target Tables**:
  - `Raptor.dbo.DimLocation`
  - `Raptor.dbo.DimDate`

## Phase 2: Create External Schema

Since Redshift Serverless is not publicly accessible, you'll need to execute the SQL commands from within the VPC. Here are your options:

### Option 1: AWS Redshift Query Editor v2 (Recommended)

1. Navigate to AWS Console → Amazon Redshift → Query Editor v2
2. Connect to workgroup `redshift-fed-prod-workgroup`
3. Use admin credentials from Secrets Manager
4. Execute the SQL script below

### Option 2: Bastion Host/EC2 Instance

Connect from an EC2 instance within the VPC using `psql`:

```bash
# Get admin password from Secrets Manager
export AWS_PROFILE=459286107047_svc_data_prod
aws secretsmanager get-secret-value \
    --secret-id arn:aws:secretsmanager:us-west-2:459286107047:secret:redshift-fed-prod-redshift-admin-20251205060308579300000001-ufJv9W \
    --region us-west-2 \
    --query SecretString \
    --output text | jq -r '.password'

# Connect to Redshift
psql -h redshift-fed-prod-workgroup.459286107047.us-west-2.redshift-serverless.amazonaws.com \
     -p 5439 \
     -d dev \
     -U admin
```

### SQL Script to Create External Schema

```sql
-- Create external schema for MSSQL Raptor database
CREATE EXTERNAL SCHEMA IF NOT EXISTS raptor_external
FROM SQLSERVER
DATABASE 'Raptor'
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
```

## Testing Federated Queries

### Test DimLocation Table

```sql
-- Count rows
SELECT COUNT(*) as total_rows
FROM raptor_external.dbo.DimLocation;

-- Sample data
SELECT TOP 10 *
FROM raptor_external.dbo.DimLocation
LIMIT 10;
```

### Test DimDate Table

```sql
-- Count rows
SELECT COUNT(*) as total_rows
FROM raptor_external.dbo.DimDate;

-- Sample data
SELECT TOP 10 *
FROM raptor_external.dbo.DimDate
LIMIT 10;
```

### Performance Testing

```sql
-- Check query execution plan
EXPLAIN
SELECT * FROM raptor_external.dbo.DimLocation LIMIT 100;

-- Monitor federated query performance
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
```

## Cost Monitoring

### Current Configuration Costs (Estimated)

- **Redshift Serverless**:
  - Base: 32 RPUs
  - Cost: ~$0.375 per RPU-hour
  - Estimated monthly (assuming 8 hours/day usage): $288/month
  - Pay only for what you use

- **Secrets Manager**: $0.40/month per secret
  - Redshift admin: $0.40/month
  - Total: $0.40/month

- **CloudWatch Logs**: $0.50/GB ingested
  - Estimated: $5-10/month

- **DynamoDB**: Pay-per-request
  - Terraform state locking: <$1/month

- **S3**: Negligible (state files and logs)

**Total Estimated Monthly Cost**: ~$294-299/month

### Cost Optimization Tips

1. **Redshift Serverless**:
   - Automatically scales to zero when not in use
   - Consider setting usage limits in AWS Console
   - Monitor RPU usage via CloudWatch

2. **Reduce Base Capacity**:
   - If queries are infrequent, reduce base_capacity to 16 RPUs
   - Edit `terraform/variables.tf` and redeploy

## Monitoring

### CloudWatch Metrics

Monitor these metrics in CloudWatch:

- `AWS/Redshift-Serverless`
  - ComputeCapacity (RPUs)
  - DatabaseConnections
  - QueryRuntime
  - QueriesCompletedPerSecond

### CloudWatch Logs

View logs at: `/aws/redshift/redshift-fed-prod`

- User activity logs
  - Connection logs
- Query logs

### Redshift Console

- View query history in Redshift console
- Monitor workgroup performance
- Check compute usage

## Security

### Access Control

1. **IAM Roles**: Least-privilege access configured
2. **Secrets Manager**: Credentials stored securely
3. **VPC**: Redshift in private subnets
4. **Security Group**: Limited ingress rules

### Secrets

Retrieve secrets using AWS CLI:

```bash
# Redshift admin credentials
aws secretsmanager get-secret-value \
    --secret-id arn:aws:secretsmanager:us-west-2:459286107047:secret:redshift-fed-prod-redshift-admin-20251205060308579300000001-ufJv9W \
    --region us-west-2

# MSSQL credentials
aws secretsmanager get-secret-value \
    --secret-id gndataeng/prod/db-mssql/raptor/analytics \
    --region us-west-2
```

## Troubleshooting

### Connection Timeouts

If you experience connection timeouts:
- Verify you're connecting from within the VPC
- Check security group rules allow inbound on port 5439
- Verify Redshift workgroup is active

### External Schema Creation Fails

If CREATE EXTERNAL SCHEMA fails:
- Verify MSSQL database is accessible from Redshift VPC
- Check security group allows outbound on port 4070
- Verify MSSQL secret has correct credentials
- Test connectivity to LSNRGNP04A.ad.idelb.com:4070

### Query Performance Issues

If federated queries are slow:
- Use EXPLAIN to check query pushdown
- Consider materializing frequently accessed data
- Verify network connectivity to MSSQL
- Check MSSQL database performance

## Next Steps

### Phase 3: Query Optimization
- [ ] Create views for common query patterns
- [ ] Implement materialized views for frequently accessed data
- [ ] Configure WLM queues for query prioritization
- [ ] Set up query monitoring rules

### Phase 4: Hybrid Data Integration
- [ ] Design unified data model
- [ ] Create stored procedures
- [ ] Implement data mart schemas
- [ ] Configure data refresh strategies

### Phase 5: Security & Governance
- [ ] Implement RBAC with database groups
- [ ] Configure column-level security
- [ ] Set up row-level security policies
- [ ] Enable comprehensive audit logging

## Terraform Commands

### View current infrastructure

```bash
export AWS_PROFILE=459286107047_svc_data_prod
cd terraform
terraform show
```

### Update infrastructure

```bash
# Make changes to .tf files
terraform plan -out=tfplan
terraform apply tfplan
```

### Destroy infrastructure (if needed)

```bash
terraform plan -destroy -out=tfplan-destroy
terraform apply tfplan-destroy
```

## Resources

- **Jira Epic**: [OPS-49969](https://golfnow.atlassian.net/browse/OPS-49969)
- **GitHub Repo**: https://github.com/GolfNowEng/aws-redshift-fed
- **Project Spec**: [PROJECT_SPEC.md](PROJECT_SPEC.md)
- **Terraform State**: `s3://gndataeng-terraform-state-prod/redshift-federated/terraform.tfstate`

## Support

For issues or questions:
- Create an issue in GitHub repository
- Refer to [PROJECT_SPEC.md](PROJECT_SPEC.md) for detailed documentation
- Contact Data Engineering team

---

**Last Updated**: 2025-12-05
**Deployed By**: Claude Code
**Status**: Phase 1 Complete ✓
