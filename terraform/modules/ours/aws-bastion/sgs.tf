resource "aws_security_group" "bastion-sg" {
  name        = "${var.deploy_env}-bastion-sg"
  description = "Bastion Server Security Group"
  vpc_id      = "${var.vpc_id}"

  tags = {
    name        = "${var.deploy_env}-bastion-sg"
    Terraform   = "true"
    aws_profile = "${var.aws_profile}"
    res_class   = "${var.res_class}"
    deploy_env  = "${var.deploy_env}"
    Environment = "${var.deploy_env}"
  }
}

resource "aws_security_group_rule" "bastion-sg-ssh-tcp-sgr" {
  count                    = "${length(var.mgmt-whitelist-cidrs) > 0 ? 1 : 0}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion-elb-sg.id}"

  security_group_id = "${aws_security_group.bastion-sg.id}"
  description       = "SSH from whitelist"
}

resource "aws_security_group_rule" "bastion-sg-egress-tcp-sgr" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bastion-sg.id}"
  description       = "Allow any outbound"
}
