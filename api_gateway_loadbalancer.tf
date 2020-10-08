resource "kubernetes_service" "api_gateway_loadbalancer" {
  count = var.create_loadbalancer ? 1 : 0
  metadata {
    name      = "api-gateway-loadbalancer"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
    labels = {
      name = "api-gateway-loadbalancer"
    }
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"       = "http"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"              = "443"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"               = module.acm.this_acm_certificate_arn
    }

  }

  spec {
    port {
      name        = "https"
      port        = "443"
      target_port = "8000"
      protocol    = "TCP"
    }

    load_balancer_source_ranges = var.load_balancer_source_ranges

    selector = {
      name = "api-gateway"
    }

    type = "LoadBalancer"
  }
}
