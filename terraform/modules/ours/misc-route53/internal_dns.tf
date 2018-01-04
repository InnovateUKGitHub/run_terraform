# Private hosted parent zone
data "aws_route53_zone" "private-domain" {
  name = "${replace(var.aws_profile, var.org_id, "") }.${var.private-domain}"
}

# Declaration of private hosted zone
resource "aws_route53_zone" "private-domain" {
  name          = "${var.deploy_env}.${replace(var.aws_profile, var.org_id, "") }.${var.private-domain}"
  comment       = "Private hosted zone. Managed by terraform"
  vpc_id        = "${var.vpc-id}"
  force_destroy = "${var.force_destroy_private_hosted_zone}"
}

# Zone delegation within private zone
resource "aws_route53_record" "private-delegation" {
  zone_id = "${data.aws_route53_zone.private-domain.zone_id}"
  name    = "${var.deploy_env}"
  type    = "NS"
  ttl     = "300"
  records = ["${aws_route53_zone.private-domain.name_servers}"]
}

# Declaration of dns rersources
resource "aws_route53_record" "private-bastion" {
  zone_id = "${data.aws_route53_zone.private-domain.zone_id}"
  name    = "bastion"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.elb-bastion-dns-name}"]
}
