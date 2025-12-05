# DMS Zero-ETL Implementation Guide

## Project Pivot: From Federated Queries to DMS Zero-ETL

**Issue Discovered**: Amazon Redshift federated queries only support PostgreSQL and MySQL, not SQL Server.

**Solution**: Use AWS Database Migration Service (DMS) for Zero-ETL integration from SQL Server to Redshift.

## What's Been Implemented

### ✓ Infrastructure Components Created

1. **DMS IAM Roles** (`terraform/modules/dms-iam/`)
   - `dms-vpc-role` - VPC management
   - `dms-cloudwatch-logs-role` - Logging access
   - `dms-s3-role` - S3 and Redshift access

2. **DMS Module** (`terraform/modules/dms/`)
   - Replication instance (dms.t3.medium)
   - Source endpoint (SQL Server)
   - Target endpoint (Redshift)
   - Replication task (full-load-and-cdc)
   - S3 staging bucket

3. **Table Mappings** (`terraform/dms-table-mappings.json`)
   - DimLocation table
   - DimDate table
   - Schema transformation (dbo → public)
   - Name transformation (convert to lowercase)

4. **Redshift Infrastructure** (Already Deployed)
   - Serverless namespace
   - Workgroup
   - IAM roles
   - CloudWatch logging

## Architecture

```
SQL Server (LSNRGNP04A:4070)
         ↓
    DMS Replication Instance
         ↓
   S3 Staging Bucket
         ↓
 Redshift Serverless
```

## Next Steps to Deploy

### Step 1: Review Configuration

Current settings:
- **DMS Instance**: dms.t3.medium (~$146/month)
- **Storage**: 100 GB
- **Multi-AZ**: Disabled (can enable for HA)
- **Source**: SQL Server Raptor database
- **Target**: Redshift dev database
- **Tables**: DimLocation, DimDate

### Step 2: Pre-Deployment Checklist

Before deploying, ensure:

- [ ] SQL Server has CDC enabled (if using incremental replication)
- [ ] SQL Server Agent is running
- [ ] Network connectivity from VPC to SQL Server (port 4070)
- [ ] MSSQL credentials in Secrets Manager are correct
- [ ] Redshift is accessible from DMS replication instance

### Step 3: Deploy DMS Infrastructure

```bash
# Set AWS profile
export AWS_PROFILE=459286107047_svc_data_prod

# Navigate to terraform directory
cd terraform

# Plan deployment
terraform plan -out=tfplan-dms

# Review the plan (should show ~15 new resources)
# - 3 IAM roles
# - 1 DMS subnet group
# - 1 DMS replication instance
# - 2 DMS endpoints
# - 1 DMS replication task
# - 1 S3 bucket
# - Supporting resources

# Apply if everything looks good
terraform apply tfplan-dms
```

**Expected Duration**: 15-20 minutes for DMS replication instance creation

### Step 4: Start Replication Task

After deployment, start the replication task:

```bash
# Get the task ARN from Terraform output
TASK_ARN=$(terraform output -raw dms_replication_task_arn)

# Start the replication task
aws dms start-replication-task \
    --replication-task-arn $TASK_ARN \
    --start-replication-task-type start-replication \
    --region us-west-2
```

### Step 5: Monitor Replication

Monitor progress via AWS Console or CLI:

```bash
# Check task status
aws dms describe-replication-tasks \
    --filters "Name=replication-task-arn,Values=$TASK_ARN" \
    --region us-west-2

# View CloudWatch logs
aws logs tail /aws/dms/tasks/redshift-fed-prod-replication-task \
    --follow \
    --region us-west-2
```

**CloudWatch Metrics to Monitor**:
- `FullLoadThroughputRowsSource` - Rows read from source
- `FullLoadThroughputRowsTarget` - Rows written to target
- `CDCLatencySource` - CDC lag time
- `CDCIncomingChanges` - Number of changes captured

### Step 6: Validate Data in Redshift

Once full load completes, validate data:

```sql
-- Connect to Redshift
-- Endpoint: redshift-fed-prod-workgroup.459286107047.us-west-2.redshift-serverless.amazonaws.com:5439
-- Database: dev
-- Schema: public

-- Check tables were created
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('dimlocation', 'dimdate');

-- Count rows in DimLocation
SELECT COUNT(*) as row_count FROM public.dimlocation;

-- Count rows in DimDate
SELECT COUNT(*) as row_count FROM public.dimdate;

-- Sample data from DimLocation
SELECT * FROM public.dimlocation LIMIT 10;

-- Sample data from DimDate
SELECT * FROM public.dimdate LIMIT 10;
```

## Cost Breakdown

### Monthly Costs (Estimated)

**DMS Costs**:
- Replication Instance (dms.t3.medium): ~$146/month
- Data transfer (VPC to VPC): Free
- S3 staging: ~$1/month (minimal)

**Redshift Costs**:
- Serverless (32 RPUs): ~$200-500/month
- Storage: Included in RPU pricing

**Other Costs**:
- Secrets Manager: $0.80/month (2 secrets)
- CloudWatch Logs: $5-10/month

**Total**: ~$352-657/month

## Troubleshooting

### Issue: Replication Task Fails

**Check**:
1. DMS can connect to SQL Server
   ```bash
   aws dms test-connection \
       --replication-instance-arn <instance-arn> \
       --endpoint-arn <source-endpoint-arn>
   ```

2. Security group allows outbound on port 4070
3. SQL Server credentials are correct
4. Network path exists (VPN/Direct Connect)

### Issue: CDC Not Working

**Requirements for CDC**:
1. SQL Server Agent must be running
2. Database recovery model must be FULL or BULK_LOGGED
3. Enable CDC on database:
   ```sql
   USE Raptor;
   GO
   EXEC sp_changedbowner 'sa';
   EXEC sys.sp_cdc_enable_db;
   GO
   ```

4. Enable CDC on tables:
   ```sql
   EXEC sys.sp_cdc_enable_table
       @source_schema = 'dbo',
       @source_name = 'DimLocation',
       @role_name = NULL;

   EXEC sys.sp_cdc_enable_table
       @source_schema = 'dbo',
       @source_name = 'DimDate',
       @role_name = NULL;
   ```

### Issue: High Replication Lag

**Solutions**:
1. Increase replication instance size (e.g., dms.c5.large)
2. Enable Multi-AZ for better performance
3. Adjust task settings:
   - Increase `CommitRate`
   - Enable `BatchApplyEnabled`
   - Increase `MaxFullLoadSubTasks`

## Monitoring Queries

### Check DMS Task Status
```bash
aws dms describe-replication-tasks \
    --region us-west-2 \
    --query 'ReplicationTasks[*].[ReplicationTaskIdentifier,Status,ReplicationTaskStats]'
```

### View Table Statistics
```bash
aws dms describe-table-statistics \
    --replication-task-arn $TASK_ARN \
    --region us-west-2
```

### CloudWatch Logs
```bash
# Task logs
aws logs tail /aws/dms/tasks/redshift-fed-prod-replication-task \
    --follow --region us-west-2

# Source/target logs
aws logs filter-log-events \
    --log-group-name /aws/dms/tasks/redshift-fed-prod-replication-task \
    --filter-pattern "ERROR" \
    --region us-west-2
```

## Performance Tuning

### Optimize Full Load

Edit `terraform/modules/dms/main.tf`:

```hcl
FullLoadSettings = {
  TargetTablePrepMode        = "TRUNCATE_BEFORE_LOAD"  # Faster if tables exist
  MaxFullLoadSubTasks        = 16                       # More parallel tasks
  CommitRate                 = 50000                    # Larger batches
  BatchApplyEnabled          = true                     # Batch inserts
}
```

### Optimize CDC

```hcl
ChangeProcessingTuning = {
  BatchApplyPreserveTransaction = true
  BatchApplyTimeoutMin          = 1
  BatchApplyTimeoutMax          = 30
  BatchApplyMemoryLimit         = 500
  BatchSplitSize                = 0
  MinTransactionSize            = 1000
  CommitTimeout                 = 1
  MemoryLimitTotal              = 1024
  MemoryKeepTime                = 60
  StatementCacheSize            = 50
}
```

## Stopping and Starting Replication

### Stop Replication
```bash
aws dms stop-replication-task \
    --replication-task-arn $TASK_ARN \
    --region us-west-2
```

### Resume Replication
```bash
aws dms start-replication-task \
    --replication-task-arn $TASK_ARN \
    --start-replication-task-type resume-processing \
    --region us-west-2
```

### Reload Tables
```bash
# Reload specific tables
aws dms reload-tables \
    --replication-task-arn $TASK_ARN \
    --tables-to-reload '[{"SchemaName":"dbo","TableName":"DimLocation"}]' \
    --region us-west-2
```

## Next Phase: Enhancements

After successful deployment:

1. **Add More Tables**: Update `dms-table-mappings.json`
2. **Create Views**: Build analytics views on replicated data
3. **Set up Alerts**: Configure SNS notifications for failures
4. **Optimize Queries**: Add distribution/sort keys in Redshift
5. **Enable Multi-AZ**: For production high availability
6. **Schedule Maintenance**: Regular monitoring and tuning

## Resources

- [AWS DMS Documentation](https://docs.aws.amazon.com/dms/)
- [DMS SQL Server Source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html)
- [DMS Redshift Target](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.Redshift.html)
- [Architecture Document](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

---

**Status**: Ready for Deployment
**Last Updated**: 2025-12-05
**Jira Epic**: [OPS-49969](https://golfnow.atlassian.net/browse/OPS-49969)
