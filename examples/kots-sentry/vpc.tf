# todo replace "Customer"/"Namespace" parameter with "User" or "Org" ??
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${local.full_name}-vpc"
  cidr = var.cidr_block

  azs             = keys(var.subnets.private)
  private_subnets = values(var.subnets.private)
  public_subnets  = values(var.subnets.public)

  enable_dns_support   = true
  enable_dns_hostnames = true

  # single nat gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # use custom EIP with lifecycle prevent destroy
  reuse_nat_ips       = true
  external_nat_ip_ids = [aws_eip.nat_primary.id]

  enable_vpn_gateway = false

  enable_s3_endpoint = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.full_name}" = "shared"
    "kubernetes.io/role/elb"                                    = "1"
    "Customer"                                                  = var.namespace
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.full_name}" = "shared"
    "kubernetes.io/role/internal-elb"                           = "1"
    "Customer"                                                  = var.namespace
  }

  tags = map(
    "Name", "vpc-${local.full_name}",
    "Stack", local.full_name,
    "Customer", var.namespace
  )
}

resource "aws_eip" "nat_primary" {
  vpc = true

  tags = map(
    "Name", "nat-primary-${local.full_name}",
    "Stack", local.full_name,
    "Customer", var.namespace
  )
}
