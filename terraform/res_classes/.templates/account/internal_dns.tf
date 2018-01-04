# This zones need to be manually delegated
resource "aws_route53_zone" "account_private" {
  name          = "${replace(var.aws_profile, var.org_id, "") }.${var.private_domain}"
  comment       = "${var.aws_profile} internal dns"
  vpc_region    = "${var.aws_region}"
  force_destroy = false
}
