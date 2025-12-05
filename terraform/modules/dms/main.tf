# DMS Replication Subnet Group
resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_id          = "${var.project_name}-${var.environment}-dms-subnet-group"
  replication_subnet_group_description = "DMS replication subnet group for ${var.project_name}"
  subnet_ids                           = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-dms-subnet-group"
  }
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "main" {
  replication_instance_id     = "${var.project_name}-${var.environment}-replication-instance"
  replication_instance_class  = var.replication_instance_class
  allocated_storage           = var.allocated_storage
  engine_version              = var.engine_version
  multi_az                    = var.multi_az
  publicly_accessible         = false
  vpc_security_group_ids      = var.security_group_ids
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-replication-instance"
  }

  depends_on = [aws_dms_replication_subnet_group.main]
}

# DMS Source Endpoint (SQL Server)
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${var.project_name}-${var.environment}-source-sqlserver"
  endpoint_type = "source"
  engine_name   = "sqlserver"

  server_name = var.source_server_name
  port        = var.source_port
  database_name = var.source_database_name
  username    = var.source_username
  password    = var.source_password

  ssl_mode = "none" # Internal network connection

  extra_connection_attributes = "readBackupOnly=Y;safeguardPolicy=EXCLUSIVE_AUTOMATIC_TRUNCATION"

  tags = {
    Name = "${var.project_name}-${var.environment}-source-sqlserver"
  }
}

# DMS Target Endpoint (Redshift)
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${var.project_name}-${var.environment}-target-redshift"
  endpoint_type = "target"
  engine_name   = "redshift"

  server_name   = var.target_server_name
  port          = var.target_port
  database_name = var.target_database_name
  username      = var.target_username
  password      = var.target_password

  ssl_mode = "require"

  redshift_settings {
    bucket_name              = var.s3_bucket_name
    bucket_folder            = "dms-staging"
    service_access_role_arn  = var.dms_service_role_arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-target-redshift"
  }
}

# S3 Bucket for DMS staging
resource "aws_s3_bucket" "dms_staging" {
  bucket = "${var.project_name}-${var.environment}-dms-staging"

  tags = {
    Name = "${var.project_name}-${var.environment}-dms-staging"
  }
}

resource "aws_s3_bucket_public_access_block" "dms_staging" {
  bucket = aws_s3_bucket.dms_staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DMS Replication Task
resource "aws_dms_replication_task" "main" {
  replication_task_id       = "${var.project_name}-${var.environment}-replication-task"
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  table_mappings            = var.table_mappings

  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema               = ""
      SupportLobs                = true
      FullLobMode                = false
      LobChunkSize               = 64
      LimitedSizeLobMode         = true
      LobMaxSize                 = 32
      InlineLobMaxSize           = 0
      LoadMaxFileSize            = 0
      ParallelLoadThreads        = 0
      ParallelLoadBufferSize     = 0
      BatchApplyEnabled          = false
      TaskRecoveryTableEnabled   = false
    }
    FullLoadSettings = {
      TargetTablePrepMode        = "DROP_AND_CREATE"
      CreatePkAfterFullLoad      = false
      StopTaskCachedChangesApplied = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks        = 8
      TransactionConsistencyTimeout = 600
      CommitRate                 = 10000
    }
    Logging = {
      EnableLogging = true
      LogComponents = [
        {
          Id       = "SOURCE_UNLOAD"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "SOURCE_CAPTURE"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "TARGET_LOAD"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "TARGET_APPLY"
          Severity = "LOGGER_SEVERITY_INFO"
        }
      ]
    }
    ControlTablesSettings = {
      ControlSchema               = ""
      HistoryTimeslotInMinutes    = 5
      HistoryTableEnabled         = true
      SuspendedTablesTableEnabled = true
      StatusTableEnabled          = true
    }
    StreamBufferSettings = {
      StreamBufferCount   = 3
      StreamBufferSizeInMB = 8
      CtrlStreamBufferSizeInMB = 5
    }
    ChangeProcessingDdlHandlingPolicy = {
      HandleSourceTableDropped   = true
      HandleSourceTableTruncated = true
      HandleSourceTableAltered   = true
    }
    ErrorBehavior = {
      DataErrorPolicy                         = "LOG_ERROR"
      DataTruncationErrorPolicy              = "LOG_ERROR"
      DataErrorEscalationPolicy              = "SUSPEND_TABLE"
      DataErrorEscalationCount               = 0
      TableErrorPolicy                       = "SUSPEND_TABLE"
      TableErrorEscalationPolicy             = "STOP_TASK"
      TableErrorEscalationCount              = 0
      RecoverableErrorCount                  = -1
      RecoverableErrorInterval               = 5
      RecoverableErrorThrottling             = true
      RecoverableErrorThrottlingMax          = 1800
      ApplyErrorDeletePolicy                 = "IGNORE_RECORD"
      ApplyErrorInsertPolicy                 = "LOG_ERROR"
      ApplyErrorUpdatePolicy                 = "LOG_ERROR"
      ApplyErrorEscalationPolicy             = "LOG_ERROR"
      ApplyErrorEscalationCount              = 0
      FullLoadIgnoreConflicts                = true
    }
    ValidationSettings = {
      EnableValidation                 = true
      ValidationMode                   = "ROW_LEVEL"
      ThreadCount                      = 5
      PartitionSize                    = 10000
      FailureMaxCount                  = 10000
      RecordFailureDelayInMinutes      = 5
      RecordSuspendDelayInMinutes      = 30
      MaxKeyColumnSize                 = 8096
      TableFailureMaxCount             = 1000
      ValidationOnly                   = false
      HandleCollationDiff              = false
      RecordFailureDelayLimitInMinutes = 0
      SkipLobColumns                   = false
      ValidationPartialLobSize         = 0
      ValidationQueryCdcDelaySeconds   = 0
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-replication-task"
  }

  depends_on = [
    aws_dms_replication_instance.main,
    aws_dms_endpoint.source,
    aws_dms_endpoint.target
  ]
}

# CloudWatch Log Group for DMS
resource "aws_cloudwatch_log_group" "dms" {
  name              = "/aws/dms/tasks/${var.project_name}-${var.environment}-replication-task"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-dms-logs"
  }
}
