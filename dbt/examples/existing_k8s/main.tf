provider "aws" {
  profile = "dbt-cloud-single-tenant"
  region  = var.region
  assume_role {
    role_arn = var.creation_role_arn
  }
}

# retrieve the subnet IDs corresponding to the private IP CIDR blocks
data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
  filter {
    name   = "cidr-block"
    values = values(var.subnets.private)
  }
}

module "single_tenant_existing" {

  source = "..\/..\/.."

  namespace               = var.namespace
  environment             = var.environment
  k8s_node_count          = 2
  k8s_node_size           = "m5.large"
  region                  = var.region
  postgres_instance_class = var.postgres_instance_class
  postgres_storage        = var.postgres_storage
  cidr_block              = var.cidr_block
  vpc_id                  = var.vpc_id
  private_subnets         = data.aws_subnet_ids.private.ids # The private subnet IDs from the VPC
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

  # enables creation of AWS SES resources for notifications
  enable_ses = true
  from_email  = "support@example.com"
  from_header = "dbt Cloud Support"

  # set to false to bypass EKS cluster creation and install into existing cluster
  create_eks_cluster = false
  custom_namespace   = "<ENTER_CUSTOM_NAMESPACE>"
  cluster_name       = "<ENTER_EXISTING_CLUSTER_NAME>"

  # set to true to install in existing namespace
  existing_namespace = true

  custom_internal_security_group_id = "<ENTER_CUSTOM_CLUSTER_SECURITY_GROUP_ID>"
}
