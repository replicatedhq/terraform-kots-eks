resource "aws_s3_bucket_object" "script" {
  count = var.create_admin_console_script ? 1 : 0
  bucket = module.dbt_cloud_app_bucket.this_s3_bucket_id
  key    = "terraform/config_script.sh"
  source = local_file.script.0.filename
}

resource "aws_s3_bucket_object" "config" {
  count = var.create_admin_console_script ? 1 : 0
  bucket = module.dbt_cloud_app_bucket.this_s3_bucket_id
  key    = "terraform/config.yaml"
  source = local_file.config.0.filename
}

resource "random_password" "secret_key" {
  count = var.create_admin_console_script ? 1 : 0
  length           = 20
  special          = true
  override_special = "/@$"
}

resource "local_file" "script" {
  count = var.create_admin_console_script ? 1 : 0
  filename = "./dbt_config.sh"
  content  = <<EOT
aws configure --profile dbt-cloud-${var.namespace}-${var.environment} set aws_access_key_id ${var.aws_access_key_id}
aws configure --profile dbt-cloud-${var.namespace}-${var.environment} set aws_secret_access_key ${var.aws_secret_access_key}
aws configure --profile dbt-cloud-${var.namespace}-${var.environment} set region ${var.region}
aws eks update-kubeconfig --profile dbt-cloud-${var.namespace}-${var.environment} --name ${var.namespace}-${var.environment} --role-arn ${var.creation_role_arn}
kubectl config set-context --current --namespace=dbt-cloud-${var.namespace}-${var.environment}
curl https://kots.io/install | bash
kubectl kots install dbt-cloud-v1${var.release_channel} --namespace dbt-cloud-${var.namespace}-${var.environment} --shared-password ${var.admin_console_password} --config-values ${local_file.config.0.filename}
EOT
}



resource "local_file" "config" {
  count = var.create_admin_console_script ? 1 : 0
  filename = "./config.yaml"
  content  = <<EOT
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  creationTimestamp: null
  name: dbt-cloud
spec:
  values:
    app_memory:
      value: ${var.app_memory}
    app_replicas:
      value: "${var.app_replicas}"
    artifacts_s3_bucket:
      value: ${local.s3_bucket_names.1}
    aws_access_key_id:
      value: ${var.aws_access_key_id}
    aws_secret_access_key:
      value: ${var.aws_secret_access_key}
    azure_storage_connection_string: {}
    database_dbname:
      value: ${var.namespace}${var.environment}
    database_embedded_storage_gb:
      value: "30"
    database_hostname:
      value: ${aws_db_instance.backend_postgres.address}
    database_password:
      value: ${var.rds_password}
    database_port:
      value: "5432"
    database_sslmode:
      value: require
    database_storage_class:
      value: default
    database_user:
      value: "${var.namespace}${var.environment}"
    datadog_enabled:
      value: "${var.datadog_enabled}"
    db_type:
      default: external
      value: external
    disable_anonymous_tracking:
      value: "0"
    django_debug_mode:
      value: "0"
    django_secret_key:
      value: ${random_password.secret_key.0.result}
    django_superuser_password:
      value: ${var.superuser_password}
    enable_okta:
      value: "0"
    encryption_method:
      default: rsa
      value: kms
    github_api_url: {}
    github_app_client_id: {}
    github_app_client_secret: {}
    github_app_configure_url: {}
    github_app_id: {}
    github_app_install_url: {}
    github_base_url: {}
    github_enabled:
      value: "0"
    github_private_key_pem: {}
    google_api_url:
      value: https://www.googleapis.com
    google_settings_type:
      default: defaults
    hostname:
      value: ${var.hostname_suffix == "" ? var.environment : var.hostname_suffix}.${var.hosted_zone_name}
    ide_storage_class:
      value: ${var.ide_storage_class}
    imageRegistry:
      value: registry.replicated.com/dbt-cloud-v1/
    kms_key_id:
      value: ${module.kms_key.key_arn}
    nginx_memory:
      value: ${var.nginx_memory}
    rsa_private_key: {}
    rsa_public_key: {}
    run_logs_s3_bucket:
      value: ${local.s3_bucket_names.0}
    s3_endpoint_url:
      default: https://s3.us-east-1.amazonaws.com
    s3_region:
      default: ${var.region}
    saml_private_key: {}
    saml_public_cert: {}
    scaling_settings_type:
      default: defaults
    scheduler_memory:
      value: ${var.scheduler_memory}
    slack_enabled:
      value: "0"
    slack_key: {}
    slack_secret: {}
    smtp_auth_enabled:
      value: "1"
    smtp_enabled:
      value: "0"
    smtp_host: {}
    smtp_password: {}
    smtp_port:
      value: "25"
    smtp_tls_enabled:
      value: "1"
    smtp_username: {}
    storage_method:
      default: s3
    system_from_email_address: {}
status: {}
EOT
}
