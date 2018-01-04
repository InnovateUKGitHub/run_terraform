module "route53" {
  source = "../../modules/ours/misc-route53"

  aws_profile          = "${var.aws_profile}"
  org_id               = "${var.org_id}"
  deploy_env           = "${var.deploy_env}"
  vpc-id               = "${module.vpc.vpc_id}"
  elb-bastion-dns-name = "${module.bastion.elb_dns_name}"
  private-domain       = "${var.private_domain}"
  public-domain        = "${var.external_domain}"
}
