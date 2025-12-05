# Scripts

This directory contains utility scripts for the AWS Redshift Federated Query project.

## Available Scripts

### create_jira_tickets.py

Creates Jira epic and stories for the project based on PROJECT_SPEC.md.

**Usage:**
```bash
python3 scripts/create_jira_tickets.py
```

**Output:**
- 1 Epic (OPS-49969)
- 8 Stories with 51 embedded tasks
- Total estimated effort: 331 hours

## Future Scripts

Additional scripts will be added as the project progresses:

- `deploy.sh` - Terraform deployment automation
- `validate-connectivity.sh` - Test connectivity to MSSQL database
- `create-external-schemas.sh` - Automated external schema creation
- `refresh-materialized-views.sh` - Trigger materialized view refreshes
- `backup-redshift.sh` - Create manual snapshots
