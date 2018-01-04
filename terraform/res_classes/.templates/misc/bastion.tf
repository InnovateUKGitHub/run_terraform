module "bastion" {
  source = "../../modules/ours/aws-bastion"

  aws_profile                 = "${var.aws_profile}"
  res_class                   = "${var.res_class}"
  deploy_env                  = "${var.deploy_env}"
  image_id                    = "${module.ecs.ami_id}"
  subnet_ids                  = ["${module.vpc.public_subnets}"]
  vpc_id                      = "${module.vpc.vpc_id}"
  key_name                    = "${aws_key_pair.auth.key_name}"
  mgmt-whitelist-cidrs        = "${var.mgmt-whitelist-cidrs}"
  user_data                   = "${data.template_file.bastion-server-userdata.rendered}"
  max_size                    = "1"
  min_size                    = "1"
  desired_capacity            = "1"
  cooldown                    = "60"
  scale_down_desired_capacity = "0"
  scale_down_min_size         = "0"
  scale_up_cron               = "0 7 * * MON-FRI"
  scale_down_cron             = "0 0 * * SUN-SAT"
}

# Template file for bastion server userdata
data "template_file" "bastion-server-userdata" {
  template = "${file("templates/cloud-init_el_bastion.sh.tpl")}"

  vars {
    aws_profile = "${var.aws_profile}"
    res_class   = "${var.res_class}"
    deploy_env  = "${var.deploy_env}"
    aws_region  = "${var.aws_region}"
  }
}
