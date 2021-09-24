locals {
  cluster_name    = var.cluster_name == "" ? "eks-${var.app_slug}" : var.cluster_name
  app_and_channel = "${var.app_slug}${var.release_channel != "" ? "/" : ""}${var.release_channel}"
  k8s_namespace   = var.k8s_namespace == "" ? "${var.app_slug}" : var.k8s_namespace
  kotsadm_fqdn    = var.kotsadm_fqdn == "" ? "${var.app_slug}-kotsadm.${var.route53_zone_name}" : var.kotsadm_fqdn
  sentry_fqdn     = var.sentry_fqdn == "" ? "${var.app_slug}-kotsadm.${var.route53_zone_name}" : var.sentry_fqdn
  vpc_name        = var.vpc_name == "" ? var.app_slug : var.vpc_name
}

variable "admin_console_password" {
  type        = string
  description = "The password to be used for the KOTS admin console web UI"
  default     = "password@!"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy, i.e. us-west-1"
}

variable "app_slug" {
  type        = string
  description = "KOTS Application Slug"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name, if not defined defaults to eks-app_slug"
  default     = ""
}

variable "create_admin_console_script" {
  type        = bool
  description = "If set to true will generate a script to automatically spin up the KOTS admin console with desired values and outputs from the module. The relevant variables below are suffixed with 'Admin Console Script' in their descriptions. These variables can also be left blank and manually entered into the script after applying if desired."
  default     = true
}

variable "instance_type" {
  type        = string
  description = "AWS instance type for worker node(s)"
  default     = "t2.xlarge"
}

variable "k8s_namespace" {
  type    = string
  default = "sentry-pro"
}

variable "kotsadm_fqdn" {
  type        = string
  description = "Set a custom FQDN for kotsadm, otherwise it defaults to app_slug-kotsadm.route53_zone_name"
  default     = ""
}

variable "license_file_path" {
  type    = string
  default = "./kots-license.yaml"
}

variable "namespace_exists" {
  type        = bool
  description = "Set to true to skip creating the namespace"
  default     = false
}

variable "release_channel" {
  type        = string
  description = "Admin Console Script - The license channel."
  default     = "stable"
}

variable "route53_zone_name" {
  type        = string
  description = "Route 53 hosted zone DNS name to use for load balancer DNS record, e.g kots.io"
}

variable "sentry_admin_username" {
  type        = string
  description = "The admin username for the Sentry dashboard."
  default     = "admin@example.com"
}

variable "sentry_admin_password" {
  type        = string
  description = "The admin password for the Sentry dashboard."
  default     = "password"
}

variable "sentry_fqdn" {
  type        = string
  description = "Set a custom FQDN for sentry, otherwise it defaults to app_slug-sentry.route53_zone_name"
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR to create"
  default     = "172.16.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
  default     = ""
}

variable "vpc_private_subnet" {
  type        = list(any)
  description = "VPC Private Subnet(s)"
  default     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "vpc_public_subnet" {
  type        = list(any)
  description = "VPC Public Subnet(s)"
  default     = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
}
