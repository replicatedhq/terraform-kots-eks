locals {
  # policy fails to create if user doesn't exist yet, so fill these lists out
  # once users exist

  key_admins = var.key_admins

  key_users = var.key_users

  iam_arn_prefix  = "arn:aws:iam::${local.account_id}"
  user_arn_prefix = "${local.iam_arn_prefix}:user/"
  root_arn        = "${local.iam_arn_prefix}:root"
}

data "aws_iam_policy_document" "kms_key_policy" {

  statement {
    sid = "enable-iam-user-permissions"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
  }

  statement {
    sid = "key-admin"
    actions = [
      "kms:*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        for user in local.key_admins : "${local.user_arn_prefix}${user}"
      ]
    }
    resources = ["*"]
  }

  statement {
    sid = "key-users"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type = "AWS"
      identifiers = [
        for user in concat(local.key_admins, local.key_users) : "${local.user_arn_prefix}${user}"
      ]
    }
    resources = ["*"]
  }
}

module "kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = "0.7.0"

  namespace               = var.namespace
  environment             = var.environment
  name                    = "key"
  description             = ""
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${var.namespace}/${var.environment}"
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  tags = map(
    "Name", "key",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
