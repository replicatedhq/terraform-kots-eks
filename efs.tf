module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.16.0"

  namespace   = var.namespace
  environment = var.environment
  name        = "efs-${var.namespace}-${var.environment}"

  region          = var.region
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets
  security_groups = [aws_security_group.internal.id]
  encrypted       = true
  kms_key_id      = module.kms_key.key_arn

  tags = map(
    "Name", "efs-${var.namespace}-${var.environment}",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
