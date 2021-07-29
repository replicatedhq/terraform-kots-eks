module "kots" {

  source = "../terraform-kots-eks"

  region             = var.region
  creation_role_arn  = var.creation_role_arn
  vpc_id             = var.vpc_id
  cidr_block         = var.cidr_block
  enable_bastion     = var.enable_bastion
  create_eks_cluster = var.create_eks_cluster
  eks_ami            = var.eks_ami
  cluster_name       = var.cluster_name

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  custom_internal_security_group_id = var.custom_internal_security_group_id
  additional_k8s_security_group_ids = var.additional_k8s_security_group_ids

  enable_rbac_sso    = var.enable_rbac_sso
  rbac_sso_view_only_role_arn = var.rbac_sso_view_only_role_arn
  rbac_sso_power_user_role_arn = var.rbac_sso_power_user_role_arn
  rbac_sso_admin_role_arn = var.rbac_sso_admin_role_arn

  k8s_node_count           = var.k8s_node_count
  k8s_node_size            = var.k8s_node_size
  additional_k8s_user_data = var.additional_k8s_user_data

  load_balancers              = local.loadbalancers
  hosted_zone_name            = var.hosted_zone_name
  load_balancer_source_ranges = var.load_balancer_source_ranges
  hostname_affix              = var.hostname_affix

  app_slug        = "dbt-cloud"
  namespace       = var.namespace
  environment     = var.environment
  release_channel = var.release_channel


  create_admin_console_script = var.create_admin_console_script
  k8s_namespace               = var.custom_namespace
  namespace_exists            = var.existing_namespace
  license_file_path           = var.license_file_path
  admin_console_password      = var.admin_console_password
  admin_console_config_yaml   = <<EOT
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  creationTimestamp: null
  name: dbt-cloud
spec:
  values:
    app_memory:
      value: ${var.app_memory}
    app_replicas:
      value: "${var.app_replicas}"
    artifacts_s3_bucket:
      value: ${local.s3_bucket_names.1}
    aws_access_key_id:
      value: ${var.aws_access_key_id}
    aws_secret_access_key:
      value: ${var.aws_secret_access_key}
    azure_storage_connection_string: {}
    database_dbname:
      value: ${var.namespace}${var.environment}
    database_embedded_storage_gb:
      value: "30"
    database_hostname:
      value: ${aws_db_instance.backend_postgres.address}
    database_password:
      value: ${var.rds_password}
    database_port:
      value: "5432"
    database_sslmode:
      value: require
    database_storage_class:
      value: default
    database_user:
      value: "${var.namespace}${var.environment}"
    datadog_enabled:
      value: "${var.enable_datadog == true ? 1 : 0}"
    db_type:
      default: external
      value: external
    disable_anonymous_tracking:
      value: "0"
    django_debug_mode:
      value: "0"
    django_superuser_password:
      value: ${var.superuser_password}
    enable_okta:
      value: "0"
    encryption_method:
      default: rsa
      value: kms
    github_api_url: {}
    github_app_client_id: {}
    github_app_client_secret: {}
    github_app_configure_url: {}
    github_app_id: {}
    github_app_install_url: {}
    github_base_url: {}
    github_enabled:
      value: "0"
    github_private_key_pem: {}
    google_api_url:
      value: https://www.googleapis.com
    google_settings_type:
      default: defaults
    hostname:
      value: ${var.hostname_affix == "" ? var.environment : var.hostname_affix}.${var.hosted_zone_name}
    ide_storage_class:
      value: ${var.ide_storage_class}
    imageRegistry:
      value: registry.replicated.com/dbt-cloud-v1/
    kms_key_id:
      value: ${module.kms_key.key_arn}
    nginx_memory:
      value: ${var.nginx_memory}
    rsa_private_key: {}
    rsa_public_key: {}
    run_logs_s3_bucket:
      value: ${local.s3_bucket_names.0}
    s3_endpoint_url:
      value: https://s3.${var.region}.amazonaws.com
    s3_region:
      value: ${var.region}
    saml_private_key: {}
    saml_public_cert: {}
    scaling_settings_type:
      default: defaults
    scheduler_memory:
      value: ${var.scheduler_memory}
    slack_enabled:
      value: "0"
    slack_key: {}
    slack_secret: {}
    smtp_auth_enabled:
      value: "1"
    smtp_enabled:
      value: "1"
    smtp_host:
      value: "${var.enable_ses ? "email-smtp.${var.region}.amazonaws.com" : var.custom_smtp_host}"
    smtp_password:
      value: "${var.enable_ses ? aws_iam_access_key.ses_key.0.ses_smtp_password_v4 : var.custom_smtp_password}"
    smtp_port:
      value: "587"
    smtp_tls_enabled:
      value: "1"
    smtp_username:
      value: "${var.enable_ses ? aws_iam_access_key.ses_key.0.id : var.custom_smtp_username}"
    storage_method:
      default: s3
    system_from_email_address:
      value: "${var.from_header} ${local.email}"
status: {}
EOT
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
  security_groups = [var.custom_internal_security_group_id == "" ? module.kots.aws_security_group_internal.0.id : var.custom_internal_security_group_id]
  encrypted       = true
  kms_key_id      = module.kms_key.key_arn

  tags = map(
    "Name", "efs-${var.namespace}-${var.environment}",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "aws_db_subnet_group" "private" {
  name       = "private-${var.namespace}-${var.environment}"
  subnet_ids = var.private_subnets

  tags = map(
  "Name", "private",
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
  vpc_security_group_ids = concat([var.custom_internal_security_group_id == "" ? module.kots.aws_security_group_internal.0.id : var.custom_internal_security_group_id], var.additional_rds_security_group_ids)

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
