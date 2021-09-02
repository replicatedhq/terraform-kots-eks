# If you prefer to not have prompts when running terraform plan, terraform apply
# provide defaults to the variables listed below

variable "aws_region" {
  type        = string
  description = "AWS region to deploy, i.e. us-west-1"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR to create"
  default     = "172.16.0.0/16"
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

variable "instance_type" {
  type        = string
  description = "AWS instance type for worker node(s)"
  default     = "t2.xlarge"
}

variable "k8s_namespace" {
  type    = string
  default = "default"
}

variable "load_balancer_source_ranges" {
  type        = string
  description = "One or more CIDR blocks to allow load balancer traffic from"
  default     = "0.0.0.0/0"
}

variable "hosted_zone_name" {
  type        = string
  description = "Hosted zone DNS name to use for load balancer DNS record, e.g kots.io"
}

variable "hosted_zone_id" {
  type        = string
  description = "Hosted zone id to use for external DNS records"
}

variable "load_balancers" {
  default = {}
}

variable "subject_alternative_names" {
  type        = list(any)
  description = "List of domain alternative name(s) comma seperated"
  # Example default = ["kotsadm.domain_name", "sentry.domain_name"]
}

# KOTS Variables
variable "app_slug" {
  type        = string
  description = "KOTS Application Slug"
}

variable "release_channel" {
  type        = string
  description = "Admin Console Script - The license channel."
  default     = ""
}

variable "namespace_exists" {
  type        = bool
  description = "Set to true to skip creating the namespace"
  default     = false
}

variable "create_admin_console_script" {
  type        = bool
  description = "If set to true will generate a script to automatically spin up the KOTS admin console with desired values and outputs from the module. The relevant variables below are suffixed with 'Admin Console Script' in their descriptions. These variables can also be left blank and manually entered into the script after applying if desired."
  default     = true
}

variable "license_file_path" {
  type    = string
  default = "./kots-sentry.yaml"
}

variable "admin_console_password" {
  type        = string
  description = "The password to be used for the KOTS admin console web UI"
  default     = "password@!"
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

variable "kotsadm_fqdn" {
  type        = string
  description = "kotsadm FQDN"
}

variable "sentry_fqdn" {
  type        = string
  description = "sentry fqdn"
}
variable "admin_console_config_yaml" {
  default = <<EOT
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  creationTimestamp: null
  name: changeme
spec:
  values: {}
status: {}
EOT
}
