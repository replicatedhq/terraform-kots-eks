# required variables
variable "namespace" {
  type = string
}
variable "environment" {
  type = string
}
variable "k8s_node_count" {
  type = number
}
variable "k8s_node_size" {
  type = string
}
variable "region" {
  type = string
}
variable "postgres_instance_class" {
  type = string
}
variable "postgres_storage" {
  type = string
}
variable "cidr_block" {
  type = string
}
variable "key_admins" {
  type = list(string)
}
variable "key_users" {
  type = list(string)
}
variable "rds_password" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "hosted_zone_name" {
  type = string
}

# optional variables
variable "enable_ses" {
  type    = bool
  default = false
}
variable "ses_email" {
  type    = string
  default = ""
}
variable "ses_header" {
  type    = string
  default = ""
}
variable "load_balancer_source_ranges" {
  type    = list(string)
  default = []
}
variable "create_admin_console_script" {
  type    = bool
  default = false
}
variable "aws_access_key_id" {
  type    = string
  default = "<ENTER_AWS_ACCESS_KEY>"
}
variable "aws_secret_access_key" {
  type    = string
  default = "<ENTER_AWS_SECRET_KEY>"
}
variable "creation_role_arn" {
  type    = string
  default = "<ENTER_CREATION_ROLE_ARN>"
}
variable "admin_console_password" {
  type    = string
  default = "<ENTER_ADMIN_CONSOLE_PASSWORD>"
}
variable "datadog_enabled" {
  type    = bool
  default = false
}
variable "superuser_password" {
  type    = string
  default = "<ENTER_SUPER_USER_PASSWORD>"
}
variable "hostname_suffix" {
  type    = string
  default = ""
}
variable "release_channel" {
  type    = string
  default = ""
}
variable "app_memory" {
  type    = string
  default = "1Gi"
}
variable "app_replicas" {
  type    = number
  default = 2
}
variable "nginx_memory" {
  type    = string
  default = "500mi"
}
variable "scheduler_memory" {
  type    = string
  default = "1Gi"
}
variable "set_additional_k8s_user_data" {
  type    = bool
  default = false
}
variable "additional_k8s_user_data" {
  type    = string
  default = ""
}
variable "create_efs_provisioner" {
  type    = bool
  default = true
}
variable "ide_storage_class" {
  type    = string
  default = "aws-efs"
}
variable "create_loadbalancer" {
  type    = bool
  default = true
}
variable "rds_backup_retention_period" {
  type = number
  default = 7
}

# locals
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}
