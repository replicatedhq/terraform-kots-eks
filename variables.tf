variable "namespace" {}
variable "environment" {}
variable "k8s_node_count" {}
variable "k8s_node_size" {}
variable "region" {}
variable "postgres_instance_class" {}
variable "postgres_storage" {}
variable "cidr_block" {}
variable "key_admins" {}
variable "key_users" {}
variable "rds_password" {}
variable "vpc_id" {}
variable "private_subnets" {}
variable "hosted_zone_name" {}
variable "enable_ses" {
  default = false
}
variable "ses_email" {
  default = ""
}
variable "load_balancer_source_ranges" {
  default = []
}

# optional admin console script vars
variable "create_admin_console_script" {
  default = false
}

variable "aws_access_key_id" {
  default = "<ENTER_AWS_ACCESS_KEY>"
}

variable "aws_secret_access_key" {
  default = "<ENTER_AWS_SECRET_KEY>"
}

variable "creation_role_arn" {
  default = "<ENTER_CREATION_ROLE_ARN>"
}

variable "admin_console_password" {
  default = "<ENTER_ADMIN_CONSOLE_PASSWORD>"
}

variable "datadog_enabled" {
  default = "0"
}

variable "superuser_password" {
  default = "<ENTER_SUPER_USER_PASSWORD>"
}

variable "hostname_suffix" {
  default = ""
}

variable "release_channel" {
  default = ""
}

variable "app_memory" {
  default = "1Gi"
}

variable "app_replicas" {
  default = "2"
}

variable "nginx_memory" {
  default = "500mi"
}

variable "scheduler_memory" {
  default = "1Gi"
}

variable "ide_storage_class" {
  default = "aws-efs"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}
