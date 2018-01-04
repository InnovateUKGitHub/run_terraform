output "deploy_env_private_domain_name" {
  value = "${aws_route53_zone.private-domain.name}"
}

output "deploy_env_private_domain_zone_id" {
  value = "${aws_route53_zone.private-domain.zone_id}"
}

output "deploy_env_public_domain_name" {
  value = "${aws_route53_zone.public-domain.name}"
}

output "deploy_env_public_domain_zone_id" {
  value = "${aws_route53_zone.public-domain.zone_id}"
}

output "deploy_env_bastion_elb_dns_name" {
  value = "${aws_route53_record.public-bastion.fqdn}"
}
