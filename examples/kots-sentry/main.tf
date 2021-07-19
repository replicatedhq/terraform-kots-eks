provider "aws" {
  profile = "default"
  region  = var.region
}

locals {
  full_name = "kots-sentry-${var.namespace}-${var.environment}"
}

module "terraform-kots-eks" {

  source = "../../terraform-kots-eks"

  region                 = "us-east-1"
  vpc_id                 = module.vpc.vpc_id
  cidr_block             = var.cidr_block
  enable_bastion         = true
  private_subnets        = values(var.subnets.private)
  public_subnets        = values(var.subnets.public)

  app_slug               = "kots-sentry"
  namespace              = "somebigbank"
  environment            = "prod"

  k8s_node_count         = 2
  k8s_node_size          = "t3.xlarge"

  custom_namespace       = var.k8s_namespace
  existing_namespace     = ! var.create_k8s_namespace
  license_file_path      = var.license_file_path
  admin_console_password = var.admin_console_password

}
