output "database_hostname" {
  value       = aws_db_instance.backend_postgres.address
  description = "The hostname (address) of the RDS database generated. This is required to be entered manually in the configuration console if not using the generated script."
}

output "efs_dns_name" {
  value       = module.efs.dns_name
  description = "The DNS name generated for the EFS instance. This may be required if creating a custom EFS provisioner."
}

output "efs_id" {
  value       = module.efs.id
  description = "The ID generated for the EFS instance. This may be required if creating a custom EFS provisioner."
}

output "instance_url" {
  value       = "${var.hostname_affix == "" ? var.environment : var.hostname_affix}.${var.hosted_zone_name}"
  description = "The URL where the dbt Cloud instance can be accessed."
}

output "kms_key_arn" {
  value       = module.kms_key.key_arn
  description = "The ARN of the KMS key created. May be manually entered for encryption in the configuration console if not using the generated script."
}

output "app_memory_bytes" {
  value       = replace(var.app_memory, "/[0-9]/", "") == "Gi" ? tonumber(replace(var.app_memory, "/[A-Za-z]/", "")) * var.app_replicas * 1074000000 : tonumber(replace(var.app_memory, "/[A-Za-z]/", "")) * var.app_replicas * 1049000
  description = "The aggregate memory allocated to all app pods in the cluster in bytes. Used for setting monitoring thresholds."
}

output "scheduler_memory_bytes" {
  value       = replace(var.scheduler_memory, "/[0-9]/", "") == "Gi" ? tonumber(replace(var.scheduler_memory, "/[A-Za-z]/", "")) * 1074000000 : tonumber(replace(var.scheduler_memory, "/[A-Za-z]/", "")) * 1049000
  description = "The aggregate memory allocated to all scheduler pods in the cluster in bytes. Used for setting monitoring thresholds."
}
