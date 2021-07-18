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
  default = "us-east-1"
}

variable "cidr_block" {
  type    = string
  default = "10.191.0.0/16"
}

variable "subnets" {
  default = {
    private = {
      us-east-1a = "10.191.0.0/20"
      us-east-1b = "10.191.16.0/20"
      us-east-1c = "10.191.32.0/20"
    }
    public = {
      us-east-1a = "10.191.64.0/20"
      us-east-1b = "10.191.80.0/20"
      us-east-1c = "10.191.96.0/20"
    }
  }
}
