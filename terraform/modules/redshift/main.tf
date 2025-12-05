# Generate random password for Redshift admin user
# Exclude characters not allowed by Redshift: /, @, ", space, \, '
resource "random_password" "redshift_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()_+={}[]<>:;.,?~-"
}

# Store Redshift admin password in Secrets Manager
resource "aws_secretsmanager_secret" "redshift_admin" {
  name_prefix = "${var.project_name}-${var.environment}-redshift-admin-"
  description = "Redshift admin credentials for ${var.namespace_name}"

  tags = {
    Name = "${var.project_name}-${var.environment}-redshift-admin"
  }
}

resource "aws_secretsmanager_secret_version" "redshift_admin" {
  secret_id = aws_secretsmanager_secret.redshift_admin.id
  secret_string = jsonencode({
    username = var.admin_username
    password = random_password.redshift_admin.result
  })
}

# Redshift Serverless Namespace
resource "aws_redshiftserverless_namespace" "main" {
  namespace_name = var.namespace_name

  admin_username = var.admin_username
  admin_user_password = random_password.redshift_admin.result

  db_name = var.database_name

  iam_roles = [var.iam_role_arn]

  log_exports = var.enable_audit_logging ? ["userlog", "connectionlog", "useractivitylog"] : []

  tags = {
    Name = var.namespace_name
  }
}

# Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "main" {
  namespace_name = aws_redshiftserverless_namespace.main.namespace_name
  workgroup_name = var.workgroup_name

  base_capacity      = var.base_capacity
  publicly_accessible = false

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = var.workgroup_name
  }
}

# CloudWatch Log Group for Redshift logs
resource "aws_cloudwatch_log_group" "redshift" {
  count = var.enable_audit_logging ? 1 : 0

  name              = "/aws/redshift/${var.namespace_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.namespace_name}-logs"
  }
}
