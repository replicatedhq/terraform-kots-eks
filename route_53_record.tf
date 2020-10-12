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
