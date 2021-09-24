resource "kubernetes_namespace" "kots_app" {
  count = var.namespace_exists || var.k8s_namespace == "default" ? 0 : 1
  metadata {
    name = local.k8s_namespace
  }
  depends_on = [
    module.eks
  ]
}

## KUBERNTES INGRESS FOR KOTS / APPLICATIONS
resource "kubernetes_ingress" "kotsadm_ingress" {
  depends_on = [
    module.eks, helm_release.ingress, local_file.script, helm_release.external_dns
  ]
  metadata {
    name      = "kotsadm-ingress"
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
    module.eks, helm_release.ingress, local_file.script, helm_release.external_dns
  ]
  metadata {
    name      = "sentry-ingress"
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
