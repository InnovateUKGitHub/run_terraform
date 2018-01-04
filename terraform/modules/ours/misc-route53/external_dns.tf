# Public hosted parent zone
data "aws_route53_zone" "public-domain" {
  name = "${replace(var.aws_profile, var.org_id, "") }.${var.public-domain}"
}

# Declaration of public hosted zone
resource "aws_route53_zone" "public-domain" {
  name          = "${var.deploy_env}.${replace(var.aws_profile, var.org_id, "") }.${var.public-domain}"
  comment       = "Public hosted zone. Managed by terraform"
  force_destroy = "${var.force_destroy_public_hosted_zone}"
}

# Zone delegation within public zone
resource "aws_route53_record" "public-delegation" {
  zone_id = "${data.aws_route53_zone.public-domain.zone_id}"
  name    = "${var.deploy_env}"
  type    = "NS"
  ttl     = "300"
  records = ["${aws_route53_zone.public-domain.name_servers}"]
}

# Declaration of dns rersources
resource "aws_route53_record" "public-bastion" {
  zone_id = "${aws_route53_zone.public-domain.zone_id}"
  name    = "bastion"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.elb-bastion-dns-name}"]
}
