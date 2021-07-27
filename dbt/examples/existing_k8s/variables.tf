variable "namespace" {
  default = "singletenant"
}

variable "environment" {
  default = "existing"
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

variable "vpc_id" {
  default = "<ENTER_VPC_ID>" # enter VPC ID where existing K8s cluster lives
}

variable "cidr_block" {
  default = "10.191.0.0/16"
  type    = string
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
