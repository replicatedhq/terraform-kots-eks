resource "aws_secretsmanager_secret" "rsa_key_pair" {
  name = "${var.namespace}-${var.environment}-ssh-rsa-key-pair-${formatdate("MMDDYYYYhhmmss", timestamp())}"

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "rsa_key_pair" {
  secret_id     = aws_secretsmanager_secret.rsa_key_pair.id
  secret_string = "{\"rsa_priv\": ${tls_private_key.rsa_key_pair.private_key_pem},\"rsa_pub\": ${tls_private_key.rsa_key_pair.public_key_pem}}"
}

resource "tls_private_key" "rsa_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "0.5.0"

  key_name   = "${var.namespace}-${var.environment}"
  public_key = tls_private_key.rsa_key_pair.public_key_openssh
}
