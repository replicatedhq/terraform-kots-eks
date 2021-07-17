
variable "namespace" {
  default = "somebigbank"
}

variable "environment" {
  default = "prod"
}

variable "region" {
  default = "us-east-1"
}

//variable "creation_role_arn" {
//  default = "<ENTER_CREATION_ROLE_ARN>"
//}
//

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
