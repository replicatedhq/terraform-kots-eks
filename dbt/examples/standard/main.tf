provider "aws" {
  profile = "default"
  region  = var.region
}

module "single_tenant_staging" {

  source = "..\/.."

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
  hosted_zone_name        = "singletenant.getdbt.com"
  creation_role_arn       = var.creation_role_arn
  # fill out with secure password before applying
  rds_password = ""

  # (optional) fill out with Admin console script values before applying or delete if not used
  create_admin_console_script = true
  aws_access_key_id           = "<ENTER_AWS_ACCESS_KEY>"
  aws_secret_access_key       = "<ENTER_AWS_SECRET_KEY>"
  superuser_password          = "<ENTER_SUPERUSER_PASSWORD>"
  admin_console_password      = "<ENTER_ADMIN_CONSOLE_PASSWORD>"
}
