// todo upload these later

//variable "this_s3_bucket_id" {
//  description = "placeholder"
//  default = "not an s3 bucket id"
//}
//
//resource "aws_s3_bucket_object" "script" {
//  count  = var.create_admin_console_script ? 1 : 0
//  bucket = var.this_s3_bucket_id
//  key    = "terraform/config_script.sh"
//  source = local_file.script.0.filename
//}
//
//resource "aws_s3_bucket_object" "config" {
//  count  = var.create_admin_console_script ? 1 : 0
//  bucket = var.this_s3_bucket_id
//  key    = "terraform/config.yaml"
//  source = local_file.config.0.filename
//}

resource "kubernetes_namespace" "kots_app" {
  count = var.existing_namespace ? 0 : 1
  metadata {
    name = var.custom_namespace == "" ? "${var.app_slug}-${var.namespace}-${var.environment}" : var.custom_namespace
  }
}

locals {
  app_and_channel = "${var.app_slug}${var.release_channel != "" ? "/" : ""}${var.release_channel}"
}

resource "local_file" "script" {
  count    = var.create_admin_console_script ? 1 : 0
  filename = "./kots_install.sh"
  content  = <<EOT
#!/bin/sh
set -euo pipefail

aws --region ${var.region} eks update-kubeconfig --name ${var.create_eks_cluster ? module.eks.0.cluster_id : var.cluster_name} ${var.creation_role_arn != "" ? "--role-arn ": ""}${var.creation_role_arn}

kubectl config set-context --current --namespace=${var.existing_namespace ? var.custom_namespace : kubernetes_namespace.kots_app.0.metadata.0.name}

[[ -x $(which kubectl-kots) ]] || curl https://kots.io/install | bash

set -v

kubectl kots install ${local.app_and_channel} \
  --namespace ${var.existing_namespace ? var.custom_namespace : kubernetes_namespace.kots_app.0.metadata.0.name} \
  --license-file ${var.license_file_path} \
  --shared-password ${var.admin_console_password} \
  --config-values ${local_file.config.0.filename} \
  --port-forward=false \
  --skip-preflights \
  --wait-duration=10m


EOT
  provisioner "local-exec" {
    command = "./kots_install.sh"
  }
  depends_on = [module.eks]
}



resource "local_file" "config" {
  count    = var.create_admin_console_script ? 1 : 0
  filename = "./config.yaml"
  content = var.admin_console_config_yaml
}
