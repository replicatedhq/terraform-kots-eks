resource "aws_security_group" "internal" {
  name        = "internal"
  description = "Allow all internal traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = map(
    "Name", "internal",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

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

resource "aws_db_subnet_group" "private" {
  name       = "private-${var.namespace}-${var.environment}"
  subnet_ids = var.private_subnets

  tags = map(
    "Name", "private",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "aws_db_instance" "backend_postgres" {
  identifier             = "${var.namespace}-${var.environment}"
  name                   = "${var.namespace}${var.environment}"
  instance_class         = var.postgres_instance_class
  allocated_storage      = var.postgres_storage
  engine                 = "postgres"
  username               = "${var.namespace}${var.environment}"
  password               = var.rds_password
  storage_encrypted      = true
  kms_key_id             = module.kms_key.key_arn
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.internal.id]

  skip_final_snapshot = true
  deletion_protection = true

  backup_retention_period  = var.rds_backup_retention_period
  delete_automated_backups = false

  lifecycle {
    ignore_changes = [password]
  }

  tags = map(
    "Name", "backend_postgres",
    "workload-type", "other",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "kubernetes_namespace" "dbt_cloud" {
  metadata {
    name = "dbt-cloud-${var.namespace}-${var.environment}"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "12.2.0"

  create_eks = true

  cluster_version = "1.16"
  cluster_name    = "${var.namespace}-${var.environment}"
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets

  worker_groups_launch_template = [
    # {
    #   name = "primary-worker-group-1-${var.k8s_node_size}"

    #   # override ami_id for this launch template
    #   # ami_id = data.aws_ami.eks_worker_ami_1_15.id
    #   # pin AMI ID to prevent node upgrade until planned
    #   # (see https://github.com/fishtown-analytics/dbt-cloud-infra-terraform/issues/66)
    #   ami_id = "ami-02d7471e04467b8de"

    #   instance_type        = var.k8s_node_size
    #   asg_desired_capacity = 0
    #   asg_min_size         = 0
    #   asg_max_size         = 0

    #   suspended_processes = ["AZRebalance"]

    #   key_name                      = "${var.namespace}-${var.environment}"
    #   additional_security_group_ids = [aws_security_group.internal.id]
    #   kubelet_extra_args            = local.kubelet_extra_args
    #   pre_userdata                  = "${local.bionic_1_15_node_userdata}${var.set_additional_k8s_user_data ? var.additional_k8s_user_data : ""}"

    #   enabled_metrics = [
    #     "GroupStandbyInstances",
    #     "GroupTotalInstances",
    #     "GroupPendingInstances",
    #     "GroupTerminatingInstances",
    #     "GroupDesiredCapacity",
    #     "GroupInServiceInstances",
    #     "GroupMinSize",
    #     "GroupMaxSize",
    #   ]
    # },
    {
      name = "primary-worker-group-1-16-${var.k8s_node_size}"

      # override ami_id for this launch template
      # ami_id = data.aws_ami.eks_worker_ami_1_15.id
      # pin AMI ID to prevent node upgrade until planned
      ami_id = data.aws_ami.eks_worker_ami_1_16.id

      instance_type        = var.k8s_node_size
      asg_desired_capacity = var.k8s_node_count
      asg_min_size         = var.k8s_node_count
      asg_max_size         = var.k8s_node_count

      suspended_processes = ["AZRebalance"]

      key_name                      = "${var.namespace}-${var.environment}"
      additional_security_group_ids = [aws_security_group.internal.id]
      kubelet_extra_args            = local.kubelet_extra_args
      pre_userdata                  = "${local.bionic_1_16_node_userdata}${var.set_additional_k8s_user_data ? var.additional_k8s_user_data : ""}"

      enabled_metrics = [
        "GroupStandbyInstances",
        "GroupTotalInstances",
        "GroupPendingInstances",
        "GroupTerminatingInstances",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupMinSize",
        "GroupMaxSize",
      ]
    },
  ]

  workers_role_name           = "${var.namespace}-${var.environment}-workers-role"
  workers_additional_policies = local.aws_worker_policy_arns

  cluster_log_retention_in_days = 0
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  cluster_endpoint_private_access = true

  manage_aws_auth = true
  map_roles = [
    {
      rolearn  = "arn:aws:iam::850607893674:role/${var.namespace}-${var.environment}-workers-role"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:masters", "system:bootstrappers"]
    },
  ]

  write_kubeconfig = false

  tags = map(
    "Name", "eks",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
