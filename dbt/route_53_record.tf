data "aws_route53_zone" "selected" {
  name = var.hosted_zone_name
}

resource "aws_route53_record" "getdbt_com" {
  count   = var.create_loadbalancer ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.environment}.${var.hosted_zone_name}"
  type    = "CNAME"
  ttl     = "60"

  records = [kubernetes_service.api_gateway_loadbalancer.0.load_balancer_ingress.0.hostname]
}

data "aws_elb_hosted_zone_id" "main" {}

resource "aws_route53_record" "alias" {
  count   = var.create_alias_record ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.alias_domain_name
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = kubernetes_service.api_gateway_loadbalancer.0.load_balancer_ingress.0.hostname
    zone_id                = data.aws_elb_hosted_zone_id.main.id
  }
}
