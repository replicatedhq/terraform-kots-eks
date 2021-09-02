# (Optional) Replace domain with your domain name, e.g replicated
resource "aws_acm_certificate" "domain_cert" {
  domain_name               = var.hosted_zone_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
}

data "aws_route53_zone" "domain_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "domain_record" {
  for_each = {
    for dvo in aws_acm_certificate.domain_cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.domain_zone.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "domain_validate" {
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.domain_record : record.fqdn]
}
