module "external-dns-aws" {
  depends_on = [
    module.eks, helm_release.ingress
  ]
  source  = "gitizenme/external-dns-aws/kubernetes"
  version = "1.0.7"

  domain           = var.hosted_zone_name
  k8s_cluster_name = local.cluster_name
  k8s_replicas     = 1
  k8s_namespace    = var.k8s_namespace
  hosted_zone_id   = var.hosted_zone_id
}