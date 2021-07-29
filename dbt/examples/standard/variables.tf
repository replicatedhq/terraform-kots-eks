variable "namespace" {
  default = "singletenant"
}

variable "environment" {
  default = "standard"
}

variable "region" {
  default = "ca-central-1"
}

variable "creation_role_arn" {
  default = ""
}

variable "postgres_instance_class" {
  default = "db.t3.micro"
}

variable "postgres_storage" {
  default = "100"
}

variable "key_admins" {
  default = [
    "bootstrapping",
  ]
}

variable "cidr_block" {
  default = "10.191.0.0/16"
  type    = string
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
