variable "namespace" {
  default = "singletenant"
}

variable "environment" {
  default = "standard"
}

variable "region" {
  default = "us-east-1"
}

variable "creation_role_arn" {
  default = "<ENTER_CREATION_ROLE_ARN>"
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

variable "key_users" {
  default = []
}

variable "cidr_block" {
  default = "10.190.0.0/16"
  type    = string
}

variable "subnets" {
  default = {
    private = {
      us-east-1a = "10.190.0.0/20"
      us-east-1b = "10.190.16.0/20"
      us-east-1c = "10.190.32.0/20"
    }
    public = {
      us-east-1a = "10.190.64.0/20"
      us-east-1b = "10.190.80.0/20"
      us-east-1c = "10.190.96.0/20"
    }
  }
}
