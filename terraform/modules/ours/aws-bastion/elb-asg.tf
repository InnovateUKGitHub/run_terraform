module "elb-bastion" {
  source  = "terraform-aws-modules/elb/aws"
  version = "1.0.1"

  name = "${var.deploy_env}-bastion-elb"

  subnets         = "${var.subnet_ids}"
  security_groups = ["${aws_security_group.bastion-elb-sg.id}"]
  internal        = false

  listener = [
    {
      instance_port     = "22"
      instance_protocol = "TCP"
      lb_port           = "22"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [
    {
      target              = "TCP:22"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  tags = {
    Terraform   = "true"
    aws_profile = "${var.aws_profile}"
    res_class   = "${var.res_class}"
    deploy_env  = "${var.deploy_env}"
    Environment = "${var.deploy_env}"
  }
}

module "auto-scaling-bastion" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "2.0.0"

  name = "${var.deploy_env}-bastion"

  # Launch configuration
  lc_name = "${var.deploy_env}-bastion-lc"

  image_id        = "${var.image_id}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.bastion-sg.id}"]
  key_name        = "${var.key_name}"
  user_data       = "${var.user_data}"

  # Auto scaling group
  asg_name                  = "${var.deploy_env}-bastion-asg"
  vpc_zone_identifier       = "${var.subnet_ids}"
  health_check_type         = "EC2"
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  desired_capacity          = "${var.desired_capacity}"
  wait_for_capacity_timeout = 0
  load_balancers            = ["${module.elb-bastion.this_elb_id}"]

  tags = [
    {
      key                 = "Environment"
      value               = "${var.deploy_env}"
      propagate_at_launch = true
    },
    {
      key                 = "aws_profile"
      value               = "${var.aws_profile}"
      propagate_at_launch = true
    },
    {
      key                 = "res_class"
      value               = "${var.res_class}"
      propagate_at_launch = true
    },
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_schedule" "scale_up" {
  count                  = "${length(var.scale_up_cron) > 0 && length(var.scale_down_cron) > 0 ? 1 : 0}"
  autoscaling_group_name = "${module.auto-scaling-bastion.this_autoscaling_group_name}"
  scheduled_action_name  = "Scale Up"
  recurrence             = "${var.scale_up_cron}"
  min_size               = "${var.min_size}"
  max_size               = "${var.max_size}"
  desired_capacity       = "${var.desired_capacity}"
}

resource "aws_autoscaling_schedule" "scale_down" {
  count                  = "${length(var.scale_up_cron) > 0 && length(var.scale_down_cron) > 0 ? 1 : 0}"
  autoscaling_group_name = "${module.auto-scaling-bastion.this_autoscaling_group_name}"
  scheduled_action_name  = "Scale Down"
  recurrence             = "${var.scale_down_cron}"
  min_size               = "${var.scale_down_min_size}"
  max_size               = "${var.max_size}"
  desired_capacity       = "${var.scale_down_desired_capacity}"
}
