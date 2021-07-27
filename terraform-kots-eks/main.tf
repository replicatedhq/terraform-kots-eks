resource "aws_security_group" "internal" {
  count       = var.custom_internal_security_group_id == "" ? 1 : 0
  name        = "internal"
  description = "Allow all internal traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  count   = var.create_eks_cluster ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "13.0.0"

  create_eks = true

  cluster_version = "1.17"
  cluster_name    = "${var.namespace}-${var.environment}"
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets

  worker_groups_launch_template = [
    {
      name = "primary-worker-group-1-17-${var.k8s_node_size}"

      # override ami_id for this launch template
      ami_id = local.eks_worker_ami

      instance_type        = var.k8s_node_size
      asg_desired_capacity = var.k8s_node_count
      asg_min_size         = var.k8s_node_count
      asg_max_size         = var.k8s_node_count

      suspended_processes = ["AZRebalance"]

      key_name                      = "${var.namespace}-${var.environment}"
      additional_security_group_ids = concat([var.custom_internal_security_group_id == "" ? aws_security_group.internal.0.id : var.custom_internal_security_group_id], var.additional_k8s_security_group_ids)
      kubelet_extra_args            = local.kubelet_extra_args_1_17
      pre_userdata                  = "${local.bionic_node_userdata}${var.additional_k8s_user_data}"

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
  map_roles       = var.enable_rbac_sso == true ? local.map_roles_sso : []

  write_kubeconfig = false

  tags = map(
  "Name", "eks",
  "Stack", "${var.namespace}-${var.environment}",
  "Customer", var.namespace
  )
}

locals {
  map_roles_sso = [
    {
      rolearn  = var.rbac_sso_view_only_role_arn
      username = "IAMViewOnlyRole"
      groups   = ["viewonlyusers"]
    },
    {
      rolearn  = var.rbac_sso_power_user_role_arn
      username = "IAMPowerUserRole"
      groups   = ["powerusers"]
    },
    {
      rolearn  = var.rbac_sso_admin_role_arn
      username = "IAMAdministratorRole"
      groups   = ["system:masters"]
    },
  ]
}

