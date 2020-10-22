provider "aws" {
  profile = "dbt-cloud-single-tenant"
  region  = var.region
  assume_role {
    role_arn = var.creation_role_arn
  }
}

module "single_tenant_staging" {

  source = "../../"

  namespace               = var.namespace
  environment             = var.environment
  k8s_node_count          = 2
  k8s_node_size           = "m5.large"
  region                  = var.region
  postgres_instance_class = var.postgres_instance_class
  postgres_storage        = var.postgres_storage
  cidr_block              = module.vpc.vpc_cidr_block
  vpc_id                  = module.vpc.vpc_id
  private_subnets         = module.vpc.private_subnets
  key_admins              = var.key_admins
  key_users               = var.key_users
  hosted_zone_name        = "singletenant.getdbt.com"
  creation_role_arn       = var.creation_role_arn
  # fill out with secure password before applying
  rds_password = ""

  # (optional) fill out with Admin console script values before applying or delete if not used
  create_admin_console_script = true
  aws_access_key_id           = ""
  aws_secret_access_key       = ""
  superuser_password          = ""
  admin_console_password      = ""

  # allows user to set custom k8s user data
  set_additional_k8s_user_data = true
  additional_k8s_user_data     = <<-EOT
  # Custom user data
  EOT

  # disables creation of efs provisioner if a custom provisioner is desired
  create_efs_provisioner = false
  ide_storage_class      = "custom-storage-class"

  # disables creation of load balancer if a custom dns configuration is desired
  create_loadbalancer = false

  # enables creation of AWS SES resources for notifications
  enable_ses = true
  ses_email  = "support@example.com"
  ses_header = "dbt Support"

  # pass a list of CIDR blocks to restrict traffic through load balancer
  load_balancer_source_ranges = ["100.68.0.0/18", "100.67.0.0/18"]
}
