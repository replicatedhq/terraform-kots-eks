variable "k8s_namespace" {
  type    = string
  default = "kots-sentry"
}

variable "create_k8s_namespace" {
  type    = bool
  default = true
}

variable "license_file_path" {
  type    = string
  default = "./kots-sentry.yaml"
}

variable "admin_console_password" {
  type    = string
  description = "The password to be used for the KOTS admin console web UI"
  default = "lola-rules!"
}

variable "sentry_admin_username" {
  type    = string
  default = "admin@example.com"
  description = "The admin username for the Sentry dashboard."
}
variable "sentry_admin_password" {
  type    = string
  default = "sentry1@!"
  description = "The admin password for the Sentry dashboard."
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
  default = "eu-central-1"
}

variable "cidr_block" {
  type    = string
  default = "10.191.0.0/16"
}

variable "subnets" {
  default = {
    private = {
      eu-central-1a = "10.191.0.0/20"
      eu-central-1b = "10.191.16.0/20"
      eu-central-1c = "10.191.32.0/20"
    }
    public = {
      eu-central-1a = "10.191.64.0/20"
      eu-central-1b = "10.191.80.0/20"
      eu-central-1c = "10.191.96.0/20"
    }
  }
}

