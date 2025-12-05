# AWS Redshift Federated Query & Zero-ETL Integration - Project Specification


**Profile:** `459286107047_svc_data_prod`\

## Project Overview

This project implements a zero-ETL data integration solution from self-managed databases to Amazon Redshift using federated queries and direct integration patterns. The goal is to simplify data integration by eliminating traditional ETL pipelines and enabling real-time or near-real-time data access.

## Business Objectives

- **Reduce Data Latency**: Enable near real-time access to operational data in analytics environment
- **Simplify Architecture**: Eliminate complex ETL pipelines and reduce data movement overhead
- **Cost Optimization**: Reduce infrastructure costs associated with ETL processing and data duplication
- **Unified Analytics**: Provide a single interface for querying both Redshift and external data sources

## Technical Scope

### 1. Data Sources

**Primary Sources:**
- Self-managed MSSQL databases ServerName: LSNRGNP04A.ad.idelb.com,4070

**Integration Methods:**
- Federated queries for on-demand access
- Zero-ETL integration for continuous replication (Aurora)
- Hybrid approach for specific use cases

### 2. Target Architecture

**Core Components:**
- Amazon Redshift Serverless or Provisioned Cluster
- IAM roles and policies for secure access
- VPC networking configuration (Security Groups, Subnets)
   VPC: vpc-0e47374708b217ada
   SecurityGroups: sg-08dff1d69f471a135
   Subnets: subnet-0f985b2a39b8e7094, subnet-02cb1a70c7d797105
- External schemas for federated query access
- Secrets Manager for credential management
   arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux

**Optional Components:**
- AWS Glue Data Catalog integration
- AWS Lake Formation for governance
 
### 3. Key Features

#### Federated Query Capabilities
- Query external databases without data movement
- Join Redshift tables with external data sources
- Support for MSSQL dialects
- Pushdown optimization for query performance

#### Zero-ETL Integration (Aurora)
- Continuous data replication from Aurora to Redshift
- No custom code or ETL pipelines required
- Automatic schema creation and synchronization
- Support for transactional consistency

#### Security & Governance
- VPC endpoint connections for secure communication
- IAM-based authentication and authorization
- Encryption in transit and at rest
- Audit logging via CloudTrail and CloudWatch

## Technical Requirements

### Prerequisites

1. **AWS Account Setup**
   - AWS account with appropriate permissions
   - AWS Organizations (if multi-account)
   - Cost allocation tags configured

2. **Network Configuration**
   - VPC with private subnets
   - Security groups allowing Redshift connectivity
   - NAT Gateway or VPC endpoints for AWS service access
   - Network connectivity to self-managed databases (VPN/Direct Connect if on-premises)

3. **Database Requirements**
   - MSSQL 2016/2022 for federated queries
   - Aurora PostgreSQL 15.4+ or Aurora MySQL 3.05+ for zero-ETL
   - Database users with read permissions
   - Network access rules allowing Redshift connections

4. **IAM Permissions**
   - Redshift cluster/serverless namespace admin
   - Secrets Manager read/write access
   - VPC and networking permissions
   - CloudWatch logs write access

### Infrastructure Components

#### Amazon Redshift
```
Configuration:
- Type: Serverless (recommended) or Provisioned
- Compute: Redshift Processing Units (RPUs) or node type (dc2.large/ra3.xlplus)
- Storage: Managed storage (serverless) or attached storage (provisioned)
- VPC: Isolated VPC or shared VPC
- Public Access: Disabled (access via VPC endpoints)
```

#### External Database Connections
```
Requirements:
- Database endpoint resolvable from Redshift VPC
- Security group allowing inbound from Redshift CIDR
- Database user with SELECT privileges
- SSL/TLS enabled for secure communication
```

#### Secrets Manager
```
Purpose: Store database credentials
Format:
{
  "username": "<db_user>",
  "password": "<db_password>",
  "host": "<db_endpoint>",
  "port": <port>,
  "dbname": "<database_name>",
  "engine": "postgres|mysql"
}
```

## Implementation Phases

### Phase 1: Foundation Setup (Week 1-2)

**Tasks:**
1. Provision Amazon Redshift cluster/namespace
   - Configure VPC, subnets, security groups
   - Set up parameter groups and configurations
   - Enable audit logging to S3

2. Network Configuration
   - Establish connectivity to source databases
   - Configure security groups and NACLs
   - Test network connectivity

3. IAM Setup
   - Create IAM roles for Redshift
   - Attach policies for Secrets Manager, S3, CloudWatch
   - Configure trust relationships

4. Secrets Management
   - Create secrets for each data source
   - Test secret retrieval
   - Set up rotation schedules

**Deliverables:**
- Terraform/CloudFormation infrastructure code
- Network connectivity validation report
- IAM policy documentation

### Phase 2: Federated Query Implementation (Week 3-4)

**Tasks:**
1. Create External Schemas
   ```sql
   CREATE EXTERNAL SCHEMA external_postgres
   FROM POSTGRES
   DATABASE '<database>' SCHEMA '<schema>'
   URI '<endpoint>' PORT <port>
   IAM_ROLE 'arn:aws:iam::<account>:role/<role-name>'
   SECRET_ARN 'arn:aws:secretsmanager:<region>:<account>:secret:<name>';
   ```

2. Configure Data Sources
   - Map external schemas to source databases
   - Test connectivity and authentication
   - Validate schema discovery

3. Query Optimization
   - Analyze query plans and pushdown operations
   - Create views for commonly used queries
   - Implement materialized views for caching

4. Performance Tuning
   - Configure query monitoring rules
   - Set up workload management (WLM)
   - Optimize network bandwidth

**Deliverables:**
- External schema DDL scripts
- Query templates and best practices guide
- Performance baseline metrics

### Phase 3: Zero-ETL Integration for Aurora (Week 5-6)

**Note:** This phase applies only if using Aurora as a source

**Tasks:**
1. Enable Aurora Zero-ETL Integration
   - Create zero-ETL integration resource
   - Configure source Aurora cluster
   - Specify target Redshift namespace

2. Initial Data Load
   - Monitor initial snapshot and replication
   - Validate data completeness
   - Check for replication lag

3. Schema Mapping
   - Verify automatic schema creation in Redshift
   - Document data type mappings
   - Handle any schema conflicts

4. Monitoring Setup
   - Configure CloudWatch metrics
   - Set up alerts for replication lag
   - Monitor integration health

**Deliverables:**
- Zero-ETL integration configuration
- Data validation scripts
- Monitoring dashboard

### Phase 4: Hybrid Data Integration (Week 7-8)

**Tasks:**
1. Create Unified Views
   - Join Redshift tables with external data
   - Create abstraction layer for end users
   - Implement row-level security

2. Query Patterns Implementation
   - Develop common query templates
   - Create stored procedures
   - Build data mart schemas

3. Data Refresh Strategy
   - Schedule materialized view refreshes
   - Implement incremental load patterns (if needed)
   - Configure cache invalidation

**Deliverables:**
- Unified data model documentation
- Query library
- Data refresh schedule

### Phase 5: Security & Governance (Week 9)

**Tasks:**
1. Access Control
   - Implement RBAC using database groups
   - Configure column-level security
   - Set up row-level security policies

2. Audit Configuration
   - Enable user activity logging
   - Configure CloudTrail for API calls
   - Set up log aggregation

3. Encryption
   - Verify encryption at rest (KMS)
   - Ensure TLS for connections
   - Document key management

4. Compliance
   - Data classification
   - Retention policies
   - PII handling procedures

**Deliverables:**
- Security policy documentation
- Audit report templates
- Compliance checklist

### Phase 6: Monitoring & Operations (Week 10)

**Tasks:**
1. CloudWatch Dashboards
   - Redshift performance metrics
   - Federated query statistics
   - Zero-ETL replication metrics

2. Alerting Rules
   - Query failures
   - Replication lag thresholds
   - Storage capacity warnings
   - Connection failures

3. Operational Procedures
   - Backup and recovery processes
   - Disaster recovery plan
   - Maintenance windows

4. Documentation
   - Architecture diagrams
   - Runbook for common operations
   - Troubleshooting guide

**Deliverables:**
- CloudWatch dashboards
- Alert configuration
- Operations runbook

### Phase 7: Testing & Validation (Week 11)

**Tasks:**
1. Functional Testing
   - Validate all query patterns
   - Test data consistency
   - Verify security controls

2. Performance Testing
   - Load testing for concurrent queries
   - Benchmark federated vs local queries
   - Stress test zero-ETL replication

3. Disaster Recovery Testing
   - Failover procedures
   - Backup restoration
   - Data loss scenarios

4. User Acceptance Testing
   - End-user query validation
   - Dashboard and report testing
   - Training sessions

**Deliverables:**
- Test plans and results
- Performance benchmark report
- UAT sign-off

### Phase 8: Production Deployment (Week 12)

**Tasks:**
1. Production Cutover
   - Deploy infrastructure to production
   - Migrate configurations
   - Update DNS/endpoints

2. Go-Live Support
   - Monitor system health
   - Address issues immediately
   - Communication to stakeholders

3. Hypercare Period
   - 2-week intensive monitoring
   - Daily status reports
   - Quick resolution of issues

**Deliverables:**
- Deployment checklist
- Go-live report
- Post-implementation review

## Architecture Patterns

### Pattern 1: Federated Query Only
```
[Self-Managed DB] <--Query--> [Amazon Redshift]
                                    |
                                    v
                              [QuickSight]
```

**Use Cases:**
- Infrequent queries to operational databases
- Small data volumes
- Real-time data requirements without replication

**Pros:**
- No data duplication
- Always current data
- Simple setup

**Cons:**
- Query performance dependent on source DB
- Network latency impact
- Load on source database

### Pattern 2: Zero-ETL Integration (Aurora)
```
[Aurora DB] --Zero-ETL--> [Amazon Redshift] --> [QuickSight]
```

**Use Cases:**
- High query volume on operational data
- Analytics requiring large scans
- Data warehouse consolidation

**Pros:**
- No impact on source database
- Optimized for analytics queries
- Automatic synchronization

**Cons:**
- Replication lag (seconds to minutes)
- Additional storage costs
- Limited to Aurora sources

### Pattern 3: Hybrid Approach
```
[Aurora DB] --Zero-ETL--> [Amazon Redshift] <--Federated--> [MySQL/PostgreSQL]
                                |
                                v
                          [QuickSight]
```

**Use Cases:**
- Mix of Aurora and self-managed databases
- Different refresh requirements per source
- Cost optimization for different data sources

**Pros:**
- Flexibility in integration approach
- Optimized cost-performance balance
- Single query interface

**Cons:**
- More complex architecture
- Multiple monitoring points
- Varied performance characteristics

## Cost Estimation

### Monthly Cost Breakdown (Estimated)

**Amazon Redshift Serverless:**
- Base capacity (16 RPU-hours): ~$48/month
- Additional usage (variable): $0.375 per RPU-hour
- Estimated total: $200-500/month (depends on usage)

**Amazon Redshift Provisioned (Alternative):**
- dc2.large (2 nodes): ~$360/month
- ra3.xlplus (2 nodes): ~$4,600/month

**Zero-ETL Integration (Aurora):**
- Per GB replicated: $0.002 per GB
- Example: 100GB/day = $6/month

**Network Data Transfer:**
- VPC to VPC: Free
- Internet egress: $0.09 per GB
- VPN/Direct Connect: Variable

**Secrets Manager:**
- $0.40 per secret per month
- $0.05 per 10,000 API calls

**CloudWatch:**
- Logs ingestion: $0.50 per GB
- Metrics: First 10 metrics free, $0.30 per metric

**Total Estimated Cost: $300-800/month**
(Varies based on data volume, query frequency, and compute sizing)

## Success Metrics

### Performance Metrics
- Query response time: <5 seconds for 95th percentile
- Federated query success rate: >99%
- Zero-ETL replication lag: <5 minutes average

### Operational Metrics
- System availability: 99.9% uptime
- Incident resolution time: <2 hours for P1 issues
- Backup success rate: 100%

### Business Metrics
- Reduction in ETL pipeline maintenance: 50% time savings
- Cost reduction vs previous ETL solution: 30%
- User satisfaction score: >4.0/5.0
- Time to insight: 50% improvement

## Risk Assessment

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Network connectivity issues | High | Medium | Implement VPN redundancy, Direct Connect |
| Query performance degradation | Medium | Medium | Implement caching, materialized views |
| Zero-ETL replication lag | Medium | Low | Monitor replication metrics, alerting |
| Security vulnerabilities | High | Low | Regular security audits, IAM reviews |
| Data inconsistency | High | Low | Validation scripts, reconciliation processes |

### Operational Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Insufficient training | Medium | Medium | Comprehensive training program |
| Lack of documentation | Medium | Low | Documentation as code requirement |
| Resource constraints | Medium | Medium | Clear escalation paths, on-call rotation |
| Vendor lock-in | Low | High | Abstract critical logic, use standard SQL |

## Dependencies

### External Dependencies
- AWS service availability and SLAs
- Source database availability
- Network connectivity (VPN/Direct Connect)
- Third-party tools (if any)

### Internal Dependencies
- Database team for source access
- Network team for connectivity
- Security team for policy review
- Application team for query patterns

## Acceptance Criteria

### Functional Requirements
- [ ] Federated queries successfully access all identified data sources
- [ ] Zero-ETL integration replicates data from Aurora to Redshift
- [ ] Users can query both local and external data in single query
- [ ] Security policies enforce proper access controls
- [ ] Monitoring alerts trigger appropriately

### Non-Functional Requirements
- [ ] Query performance meets SLA requirements
- [ ] System passes security review
- [ ] Documentation is complete and accessible
- [ ] Operations team trained and confident
- [ ] Disaster recovery tested successfully

## Future Enhancements

### Phase 2 Capabilities
- Integration with additional data sources (SQL Server, Oracle via JDBC)
- Machine learning integration using Redshift ML
- Advanced data sharing across AWS accounts
- Real-time streaming ingestion (Kinesis)
- Data mesh implementation patterns

### Optimization Opportunities
- Query result caching layer
- Automated query tuning recommendations
- Cost optimization automation
- Advanced workload management
- Automated scaling policies

## References

### AWS Documentation
- [Amazon Redshift Federated Query](https://docs.aws.amazon.com/redshift/latest/dg/federated-overview.html)
- [Aurora Zero-ETL Integration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html)
- [Redshift Best Practices](https://docs.aws.amazon.com/redshift/latest/dg/best-practices.html)

### Internal Documentation
- Network architecture diagrams
- Security policies
- Naming conventions
- Tagging standards

## Appendices

### Appendix A: Terraform Module Structure
```
aws-redshift-fed/
├── modules/
│   ├── redshift/
│   ├── networking/
│   ├── iam/
│   ├── secrets/
│   └── monitoring/
├── environments/
│   ├── dev/
│   ├── stage/
│   └── prod/
├── scripts/
│   ├── setup/
│   ├── deployment/
│   └── validation/
└── docs/
    ├── architecture/
    ├── operations/
    └── troubleshooting/
```

### Appendix B: Sample Federated Query
```sql
-- Query joining Redshift table with external PostgreSQL table
SELECT
    local.customer_id,
    local.customer_name,
    external.order_count,
    external.total_amount
FROM
    redshift_schema.customers local
    INNER JOIN external_postgres.orders_summary external
        ON local.customer_id = external.customer_id
WHERE
    external.order_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY
    external.total_amount DESC
LIMIT 100;
```

### Appendix C: Monitoring Queries
```sql
-- Check federated query performance
SELECT
    query,
    userid,
    starttime,
    endtime,
    DATEDIFF(seconds, starttime, endtime) as duration_seconds
FROM
    svl_qlog
WHERE
    external_table_count > 0
ORDER BY
    starttime DESC
LIMIT 100;

-- Monitor Zero-ETL integration status
SELECT
    integration_name,
    source_db,
    target_db,
    status,
    lag_duration,
    last_sync_time
FROM
    svv_integration
ORDER BY
    last_sync_time DESC;
```

### Appendix D: Contact Information

**Project Team:**
- Project Lead: [Name]
- Technical Lead: [Name]
- Database Admin: [Name]
- Network Engineer: [Name]
- Security Lead: [Name]

**Escalation Path:**
- L1: Project team
- L2: AWS Support (Enterprise)
- L3: AWS Technical Account Manager

---

**Document Version:** 1.0
**Last Updated:** 2025-12-05
**Next Review Date:** 2025-12-19
