module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = data.aws_route53_zone.selected.name
  zone_id     = data.aws_route53_zone.selected.zone_id

  subject_alternative_names = [
    "*.${var.hosted_zone_name}"
  ]

  tags = {
    Name = "${var.environment}-${var.namespace}-getdbt-com"
  }
}
