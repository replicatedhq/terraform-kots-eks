module "kots" {

  source = "../terraform-kots-eks"

  region          = "us-east-1"
  vpc_id          = var.vpc_id
  cidr_block      = var.cidr_block
  enable_bastion  = true
  private_subnets = values(var.subnets.private)
  public_subnets  = values(var.subnets.public)

  app_slug    = "kots-sentry"
  namespace   = "somebigbank"
  environment = "prod"

  k8s_node_count = 2
  k8s_node_size  = "t3.xlarge"

  k8s_namespace       = var.k8s_namespace
  namespace_exists     = var.create_k8s_namespace
  license_file_path      = var.license_file_path
  admin_console_password = var.admin_console_password
}


module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.22.0"

  namespace   = var.namespace
  environment = var.environment
  name        = "efs-${var.namespace}-${var.environment}"

  region          = var.region
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets
  security_groups = [var.custom_internal_security_group_id == "" ? module.kots.aws_security_group.internal.0.id : var.custom_internal_security_group_id]
  encrypted       = true
  kms_key_id      = module.kms_key.key_arn

  tags = map(
    "Name", "efs-${var.namespace}-${var.environment}",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}


resource "aws_db_instance" "backend_postgres" {
  identifier             = "${var.namespace}-${var.environment}"
  name                   = "${var.namespace}${var.environment}"
  instance_class         = var.postgres_instance_class
  allocated_storage      = var.postgres_storage
  engine                 = "postgres"
  engine_version         = var.postgres_engine_version
  parameter_group_name   = var.db_parameter_group
  username               = "${var.namespace}${var.environment}"
  password               = var.rds_password
  storage_encrypted      = true
  multi_az               = var.rds_multi_az
  kms_key_id             = module.kms_key.key_arn
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = concat([var.custom_internal_security_group_id == "" ? aws_security_group.internal.0.id : var.custom_internal_security_group_id], var.additional_rds_security_group_ids)

  skip_final_snapshot = true
  deletion_protection = true

  backup_retention_period  = var.rds_backup_retention_period
  delete_automated_backups = false

  apply_immediately = var.db_apply_change_immediately

  lifecycle {
    ignore_changes = [password]
  }

  tags = map(
    "Name", "backend_postgres",
    "workload-type", "other",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

locals {
  map_roles_sso = [
    {
      rolearn  = var.rbac_sso_view_only_role_arn
      username = "IAMViewOnlyRole"
      groups   = ["viewonlyusers"]
    },
    {
      rolearn  = var.rbac_sso_power_user_role_arn
      username = "IAMPowerUserRole"
      groups   = ["powerusers"]
    },
    {
      rolearn  = var.rbac_sso_admin_role_arn
      username = "IAMAdministratorRole"
      groups   = ["system:masters"]
    },
  ]
}

