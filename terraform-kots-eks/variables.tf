# required variables
variable "app_slug" {
  type = string
  description = "The app slug to install"
}

variable "release_channel" {
  type        = string
  default     = ""
  description = "Admin Console Script - The license channel."
}

variable "license_file_path" {
  type = string
  description = "Local path to a KOTS license file"
}

variable "namespace" {
  type        = string
  description = "Used as an identifier for various infrastructure components within the module. Usually single word that or the name of the organization. For exmaple: 'fishtownanalytics'"
}

variable "environment" {
  type        = string
  description = "The name of the environment for the deployment. For example: 'dev', 'prod', 'uat', 'standard', 'etc'"
}

variable "k8s_node_count" {
  type        = number
  description = "The number of Kubernetes nodes that will be created for the EKS worker group."
}
variable "k8s_node_size" {
  type        = string
  description = "The EC2 instance type of the Kubernetes nodes that will be created for the EKS worker group."
}

variable "region" {
  type = string
  description = "The AWS region"
}

variable "cidr_block" {
  type        = string
  description = "The CIDR block of the VPC that the infrastructure will be deployed in."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC that the infrastructure will be deployed in. See examples/ for single-purpose VPC configuration"
}

variable "private_subnets" {
  type        = list(string)
  description = "The list of AWS subnet IDs for private subnets for the VPC that the infrastructure will be deployed in."
}
variable "public_subnets" {
  type        = list(string)
  description = "The list of AWS subnet IDs for public subnets for the VPC that the infrastructure will be deployed in."
  default     = []
}

variable "create_admin_console_script" {
  type        = bool
  default     = true
  description = "If set to true will generate a script to automatically spin up the KOTS admin console with desired values and outputs from the module. The relevant variables below are suffixed with 'Admin Console Script' in their descriptions. These variables can also be left blank and manually entered into the script after applying if desired."
}

# todo dex grok this
variable "creation_role_arn" {
  type        = string
  default     = "<ENTER_CREATION_ROLE_ARN>"
  description = "Admin Console Script - The ARN of the Terraform Creation Role. This is added to the script and used when setting the K8s context."
}

variable "admin_console_password" {
  type        = string
  description = "Admin Console Script - The desired password for the KOTS admin console. This is added to the script and used when spinning the admin console."
}

variable "additional_k8s_user_data" {
  type        = string
  default     = ""
  description = "Any additonal user data for K8s worker nodes. For example a curl script to install auditing software."
}
variable "create_eks_cluster" {
  type        = bool
  default     = true
  description = "Set to `false` if installing the app into an existing EKS cluster."
}

variable "namespace_exists" {
  type = bool
  default = false
  description = "Set to true to skip creating the namespace"
}

variable "k8s_namespace" {
  type        = string
  default     = ""
  description = "If set this variable will create a custom K8s namespace for the App. If not set the created namespace defaults to `<app_slug>-<namespace>-<environment>`."
}

variable "cluster_name" {
  type        = string
  default     = ""
  description = "Name of the cluster the app will be installed into. Must be set if `create_eks_cluster` is set to `false`."
}
variable "custom_internal_security_group_id" {
  type        = string
  default     = ""
  description = "The ID of an existing custom security group attached to an existing K8s cluster. This security group enables communication between the EKS worker nodes. It should be modeled after the `aws_security_group.internal` resource in this module. "
}
variable "additional_k8s_security_group_ids" {
  type        = list(string)
  default     = []
  description = "List of additional security group IDs to add to EKS cluster."
}

variable "enable_bastion" {
  type        = bool
  default     = false
  description = "Enable bastion host that has ssh access to worker nodes."
}

variable "bastion_subnet_id" {
  type        = string
  default     = ""
  description = "Subnet ID for bastion (not a CIDR)"
}

variable "eks_ami" {
  type        = string
  default     = ""
  description = "Default to pull the latest Ubuntu EKS AMI, otherwise use this one."
}
variable "enable_rbac_sso" {
  type        = bool
  default     = false
  description = "Enable creation of RBAC for specific SSO roles to access the cluster. If set to `true`, the rbac_sso_*_role_arn variables need to be set."
}
variable "rbac_sso_view_only_role_arn" {
  type        = string
  default     = ""
  description = "The role arn of the view only role to be added to the aws auth config map. "
}
variable "rbac_sso_power_user_role_arn" {
  type        = string
  default     = ""
  description = "The role arn of the power user role to be added to the aws auth config map."
}
variable "rbac_sso_admin_role_arn" {
  type        = string
  default     = ""
  description = "The role arn of the administrator role to be added to the aws auth config map."
}



# advanced


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
