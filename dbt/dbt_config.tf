locals {
  email = "${var.from_email == "" ? "" : "<${var.from_email}>"}"
}

resource "aws_s3_bucket_object" "script" {
  count  = var.create_admin_console_script ? 1 : 0
  bucket = module.dbt_cloud_app_bucket.this_s3_bucket_id
  key    = "terraform/config_script.sh"
  source = module.kots.install_script.0.filename
}

resource "aws_s3_bucket_object" "config" {
  count  = var.create_admin_console_script ? 1 : 0
  bucket = module.dbt_cloud_app_bucket.this_s3_bucket_id
  key    = "terraform/config.yaml"
  source = module.kots.config_file.0.filename
}