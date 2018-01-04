# This zones need to be manually delegated
resource "aws_route53_zone" "account_public" {
  name          = "${replace(var.aws_profile, var.org_id, "") }.${var.external_domain}"
  comment       = "${var.aws_profile} external dns"
  vpc_region    = "${var.aws_region}"
  force_destroy = false
}

resource "aws_route53_record" "account_public_mx" {
  zone_id = "${aws_route53_zone.account_public.id}"
  name    = "${replace(var.aws_profile, var.org_id,"") }.${var.external_domain}"
  type    = "MX"

  records = ["${var.mx_records}"]

  ttl = "60"
}
