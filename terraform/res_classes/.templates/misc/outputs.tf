output "public_subnets" {
  value = ["${slice(var.vpc_public_subnets, 0, length(data.aws_availability_zones.available.names))}"]
}

output "private_subnets" {
  value = ["${slice(var.vpc_private_subnets, 0, length(data.aws_availability_zones.available.names))}"]
}

output "database_subnets" {
  value = ["${slice(var.vpc_database_subnets, 0, length(data.aws_availability_zones.available.names))}"]
}

output "elasticache_subnets" {
  value = ["${slice(var.vpc_elasticache_subnets, 0, length(data.aws_availability_zones.available.names))}"]
}

output "bastion_elb_dns_name" {
  value = "${module.bastion.elb_dns_name}"
}

output "bastion_elb_dns_alias" {
  value = "${module.route53.deploy_env_bastion_elb_dns_name}"
}
