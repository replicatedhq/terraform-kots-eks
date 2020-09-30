resource "aws_iam_policy" "nodes_kubernetes" {
  name   = "nodes.kubernetes.${var.namespace}-${var.environment}"
  policy = data.aws_iam_policy_document.nodes_kubernetes.json
}

data "aws_iam_policy_document" "nodes_kubernetes" {
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
