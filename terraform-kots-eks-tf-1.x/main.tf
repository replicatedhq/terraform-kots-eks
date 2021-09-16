terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.5.0"
    }
    helm = {
      version = "2.3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_route53_zone" "selected" {
  count = 1
  name  = var.hosted_zone_name
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name    = var.cluster_name
  app_and_channel = "${var.app_slug}${var.release_channel != "" ? "/" : ""}${var.release_channel}"
  k8s_namespace   = var.k8s_namespace == "" ? "${var.app_slug}-${var.k8s_namespace}" : var.k8s_namespace
}

resource "kubernetes_namespace" "kots_app" {
  count = var.namespace_exists || var.k8s_namespace == "default" ? 0 : 1
  metadata {
    name = local.k8s_namespace
  }
}

## KUBERNTES INGRESS FOR KOTS / APPLICATIONS
resource "kubernetes_ingress" "kotsadm_ingress" {
  depends_on = [
    module.eks, helm_release.ingress, local_file.script
  ]
  metadata {
    name = "kotsadm-ingress"
    namespace = local.k8s_namespace
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "external-dns.alpha.kubernets.io/hostname"   = var.kotsadm_fqdn
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/ssl-policy"       = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate_validation.domain_validate.certificate_arn
    }
  }

  spec {
    rule {
      host = var.kotsadm_fqdn
      http {
        path {
          path = "/"
          backend {
            service_name = "kotsadm"
            service_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "sentry_ingress" {
  depends_on = [
    module.eks, helm_release.ingress, local_file.script
  ]
  metadata {
    name = "sentry-ingress"
    namespace = local.k8s_namespace
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "external-dns.alpha.kubernets.io/hostname"   = var.sentry_fqdn
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/ssl-policy"       = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate_validation.domain_validate.certificate_arn
    }
  }

  spec {
    rule {
      host = var.sentry_fqdn
      http {
        path {
          path = "/"
          backend {
            service_name = "sentry"
            service_port = 9000
          }
        }
      }
    }
  }
}

resource "local_file" "script" {
  count    = var.create_admin_console_script ? 1 : 0
  filename = "./kots_install.sh"
  content  = <<EOT
#!/bin/sh
set -euo pipefail

aws eks --region ${var.aws_region} update-kubeconfig --name ${var.cluster_name}

kubectl config set-context --current --namespace=${local.k8s_namespace}

[[ -x $(which kubectl-kots) ]] || curl https://kots.io/install | bash

set -v

kubectl kots install ${local.app_and_channel} \
  --namespace ${local.k8s_namespace} \
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
  depends_on = [module.eks, local_file.config]
}

resource "local_file" "patch" {
  count    = 1
  filename = "./patch_kots_service.sh"
  content  = <<EOT
#!/bin/sh
set -euo pipefail

kubectl patch service -n ${local.k8s_namespace} kotsadm -p '{"spec":{"type":"NodePort"}}'
kubectl patch ingress -n ${local.k8s_namespace} kotsadm-ingress -p '{"spec":{"rules":[{"host":"${var.kotsadm_fqdn}","http":{"paths":[{"backend":{"serviceName":"kotsadm","servicePort":3000},"path":"/","pathType":"Prefix"}]}}]}}'
kubectl patch service -n ${local.k8s_namespace} sentry -p '{"spec":{"type":"NodePort"}}'
kubectl patch ingress -n ${local.k8s_namespace} sentry-ingress -p '{"spec":{"rules":[{"host":"${var.sentry_fqdn}","http":{"paths":[{"backend":{"serviceName":"sentry","servicePort":9000},"path":"/","pathType":"Prefix"}]}}]}}'
EOT
  provisioner "local-exec" {
    command = "./patch_kots_service.sh"
  }
  depends_on = [local_file.script, kubernetes_ingress.sentry_ingress, kubernetes_ingress.kotsadm_ingress]
}

resource "local_file" "config" {
  count    = var.create_admin_console_script ? 1 : 0
  filename = "./config.yaml"
  content  = <<-EOT
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  name: kots-sentry
spec:
  values:
    admin_username:
      value: ${var.sentry_admin_username}
    admin_password:
      value: ${var.sentry_admin_password}
status: {}
EOT
}
