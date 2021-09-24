resource "aws_acm_certificate_validation" "domain_validate" {
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.domain_record : record.fqdn]
}

resource "aws_acm_certificate" "domain_cert" {
  domain_name = var.route53_zone_name
  subject_alternative_names = [
    local.kotsadm_fqdn,
    local.sentry_fqdn,
  ]
  validation_method = "DNS"
}
