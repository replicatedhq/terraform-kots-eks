locals {
  s3_bucket_names = [
    "com.getdbt.cloud.${var.namespace}-${var.environment}.logs",
    "com.getdbt.cloud.${var.namespace}-${var.environment}.artifacts",
  ]
}

resource "aws_s3_bucket" "bucket" {
  for_each = toset(local.s3_bucket_names)

  bucket = each.key
  acl    = "private"

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = map(
    "Name", each.key,
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  for_each = toset(local.s3_bucket_names)

  bucket = aws_s3_bucket.bucket[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

module "dbt_cloud_app_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "1.16.0"

  bucket = "com.getdbt.cloud.${var.namespace}-${var.environment}.app"
  acl    = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = map(
    "Name", "dbt_cloud_${var.namespace}-${var.environment}_app_bucket",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

module "dbt_cloud_per_branch_app_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "1.16.0"

  bucket = "com.getdbt.cloud.${var.namespace}-${var.environment}.per-branch.app"
  acl    = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = map(
    "Name", "dbt_cloud_${var.namespace}-${var.environment}_per_branch_app_bucket",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
