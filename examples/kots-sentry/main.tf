provider "aws" {
  profile = "default"
  region  = var.region
}

module "terraform-kots-eks" {

  source = "../../terraform-kots-eks"

  cidr_block = var.cidr_block
  namespace = "sentry"
  environment = "production"
  app_slug = "kots-sentry"
  k8s_node_count = 2
  k8s_node_size = "t3.xlarge"
  region = "us-east-1"
  vpc_id = module.vpc.vpc_id
  private_subnets = values(var.subnets.private)
  license_file_path = "/Users/dex/Downloads/Some Big Bank.yaml"
  admin_console_password = "soopersecret"
}
