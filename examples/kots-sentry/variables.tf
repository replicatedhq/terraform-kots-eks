variable "k8s_namespace" {
  type = string
  default = "kots-sentry"
}

variable "create_k8s_namespace" {
  type = bool
  default = true
}
variable "license_file_path" {
  type = string
  default = "./kots-sentry.yaml"
}

variable "admin_console_password" {
  type = string
  default = "sooperSecret"
}

# NOT A K8S NAMESPACE -- more of an org identifier
variable "namespace" {
  type = string
  default = "somebigbank"
}

variable "environment" {
  type = string
  default = "prod"
}

variable "region" {
  type = string
  default = "ca-central-1"
}

variable "cidr_block" {
  type    = string
  default = "10.191.0.0/16"
}

variable "subnets" {
  default = {
    private = {
      ca-central-1a = "10.191.0.0/20"
      ca-central-1b = "10.191.16.0/20"
      ca-central-1d = "10.191.32.0/20"
    }
    public = {
      ca-central-1a = "10.191.64.0/20"
      ca-central-1b = "10.191.80.0/20"
      ca-central-1d = "10.191.96.0/20"
    }
  }
}

