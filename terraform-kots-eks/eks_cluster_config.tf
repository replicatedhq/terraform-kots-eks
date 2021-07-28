data "aws_eks_cluster" "cluster" {
  name = var.create_eks_cluster ? module.eks.0.cluster_id : var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.create_eks_cluster ? module.eks.0.cluster_id : var.cluster_name
}

data "aws_ami" "eks_worker_ami_1_17" {
  count = var.create_eks_cluster ? 1 : 0
  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_1.20/images/*"]
  }

  most_recent = true
  owners      = ["099720109477"]

  tags = map(
    "Name", "eks_worker_ami_1_17",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

locals {
  eks_worker_ami = var.eks_ami != "" ? var.eks_ami : data.aws_ami.eks_worker_ami_1_17.0.id

  # use built-in policies when posssible
  aws_worker_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]

}

resource "aws_iam_policy" "nodes_kubernetes" {
  count  = var.create_eks_cluster ? 1 : 0
  name   = "nodes.kubernetes.${var.namespace}-${var.environment}"
  policy = data.aws_iam_policy_document.nodes_kubernetes.0.json
}

# TODO remove KMS allow statements, and allow module caller to
# include additional arbitrary IAM statements via vars
data "aws_iam_policy_document" "nodes_kubernetes" {
  count = var.create_eks_cluster ? 1 : 0
  statement {
    actions = [
      "ec2:Describe*",
    ]

    resources = ["*"]
  }

  statement {
    actions = ["route53:GetChange"]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    sid = "kmsAllow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
    ]

    resources = [
      "*"
    ]
  }
}
