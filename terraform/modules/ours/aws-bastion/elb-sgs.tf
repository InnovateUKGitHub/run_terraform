resource "aws_security_group" "bastion-elb-sg" {
  name        = "${var.deploy_env}-bastion-elb-sg"
  description = "Bastion ELB Security Group"
  vpc_id      = "${var.vpc_id}"

  tags = {
    name        = "${var.deploy_env}-bastion-elb-sg"
    Terraform   = "true"
    aws_profile = "${var.aws_profile}"
    res_class   = "${var.res_class}"
    deploy_env  = "${var.deploy_env}"
    Environment = "${var.deploy_env}"
  }
}

resource "aws_security_group_rule" "bastion-elb-sg-ssh-public-tcp-sgr" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.mgmt-whitelist-cidrs}"]

  security_group_id = "${aws_security_group.bastion-elb-sg.id}"
  description       = "SSH from outside"
}

resource "aws_security_group_rule" "bastion-elb-sg-egress-public-tcp-sgr" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bastion-elb-sg.id}"
  description       = "Allow any outbound"
}
