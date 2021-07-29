provider "aws" {
  profile = "default"
  region  = var.region
}

locals {
  full_name = "kots-sentry-${var.namespace}-${var.environment}"
}

module "terraform-kots-eks" {

  source = "../../terraform-kots-eks"

  region            = var.region
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.cidr_block
  enable_bastion    = false
  bastion_subnet_id = module.vpc.public_subnets[0]
  private_subnets   = module.vpc.private_subnets
  public_subnets    = module.vpc.public_subnets
  creation_role_arn = ""

  app_slug    = "kots-sentry"
  namespace   = var.namespace
  environment = var.environment

  k8s_node_count = 2
  k8s_node_size  = "t3.xlarge"

  custom_namespace          = var.k8s_namespace
  existing_namespace        = !var.create_k8s_namespace
  license_file_path         = var.license_file_path
  admin_console_password    = var.admin_console_password
  admin_console_config_yaml = <<EOT
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  name: kots-sentry
spec:
  values:
    admin_username:
      value: ${var.sentry_admin_username}
    admin_password:
      value: ${var.sentry_admin_password}
status: {}
EOT

}

output "next_steps" {
  value = <<EOT


    kubectl kots admin-console --namespace ${var.k8s_namespace}

EOT
}
