locals {
  example_load_balancers = {
    kots = {
      port = 3000
      selector = {
        app = "kotsadm"
      }
    }
  }
}

variable "load_balancers" {
  default = {}
}

variable "hosted_zone_name" {
  type        = string
  description = "hosted zone to use for load balancer DNS record"
  default     = ""
}

variable "load_balancer_source_ranges" {
  type        = list(string)
  description = "One or more CIDR blocks to allow load balancer traffic from"
  default = [
    "0.0.0.0/0"
  ]
}

data "aws_route53_zone" "selected" {
  count = length(var.load_balancers) > 0 ? 1 : 0
  name  = var.hosted_zone_name
}

resource "kubernetes_service" "api_gateway_loadbalancer" {
  for_each   = var.load_balancers
  depends_on = [module.eks]
  metadata {
    name      = each.key
    namespace = var.k8s_namespace
    labels = {
      name = each.key
      app  = each.key
    }
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"       = "http"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"              = "443"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"               = module.acm.0.this_acm_certificate_arn
    }

  }

  spec {
    port {
      name        = "https"
      port        = "443"
      target_port = each.value.port
      protocol    = "TCP"
    }

    load_balancer_source_ranges = var.load_balancer_source_ranges

    selector = each.value.selector

    type = "LoadBalancer"
  }
}


resource "aws_route53_record" "kots_dns" {
  for_each = var.load_balancers
  zone_id  = data.aws_route53_zone.selected.0.zone_id
  name     = "${each.key}.${var.environment}.${var.hosted_zone_name}"
  type     = "CNAME"
  ttl      = "60"

  records = [lookup(kubernetes_service.api_gateway_loadbalancer, each.key, ).load_balancer_ingress.0.hostname]
}

module "acm" {
  count   = length(var.load_balancers) > 0 ? 1 : 0
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = data.aws_route53_zone.selected.0.name
  zone_id     = data.aws_route53_zone.selected.0.zone_id

  subject_alternative_names = [
    "*.${var.environment}.${var.hosted_zone_name}"
  ]

  tags = {
    Name = "${var.app_slug}-${var.environment}-${var.namespace}"
  }
}
output "ingress_lbs" {
  value = [
    for record in values(aws_route53_record.kots_dns) :
    "https://${record.name}"
  ]
}
