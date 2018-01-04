output "sg_id" {
  value = "${aws_security_group.bastion-sg.id}"
}

output "elb_sg_id" {
  value = "${aws_security_group.bastion-elb-sg.id}"
}

output "elb_dns_name" {
  value = "${module.elb-bastion.this_elb_dns_name}"
}
