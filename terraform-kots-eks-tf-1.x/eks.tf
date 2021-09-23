module "eks" {
  depends_on = [
    module.vpc
  ]
  source  = "terraform-aws-modules/eks/aws"
  version = "17.20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type        = var.instance_type
      asg_desired_capacity = 2 // Update this value to desired number of controlplane nodes
      asg_max_size         = 2
      asg_min_size         = 2

    }
  ]

  write_kubeconfig            = true
  kubeconfig_output_path      = "./"
  workers_additional_policies = [aws_iam_policy.worker_policy.arn]
}

resource "aws_iam_policy" "worker_policy" {
  description = "Worker policy for the ALB Ingress"

  policy = file("iam_policy.json")
}