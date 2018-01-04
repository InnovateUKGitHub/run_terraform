data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.9.1"

  name = "${var.deploy_env}-vpc"
  cidr = "${var.vpc_cidr}"

  azs                 = ["${data.aws_availability_zones.available.names}"]
  private_subnets     = "${slice(var.vpc_private_subnets, 0, length(data.aws_availability_zones.available.names))}"
  public_subnets      = "${slice(var.vpc_public_subnets, 0, length(data.aws_availability_zones.available.names))}"
  database_subnets    = "${slice(var.vpc_database_subnets, 0, length(data.aws_availability_zones.available.names))}"
  elasticache_subnets = "${slice(var.vpc_elasticache_subnets, 0, length(data.aws_availability_zones.available.names))}"

  create_database_subnet_group = false
  enable_nat_gateway           = true
  enable_vpn_gateway           = true
  enable_s3_endpoint           = true
  enable_dynamodb_endpoint     = true
  enable_dhcp_options          = true
  dhcp_options_domain_name     = "${var.private_domain}"

  tags = {
    Terraform   = "true"
    aws_profile = "${var.aws_profile}"
    res_class   = "${var.res_class}"
    deploy_env  = "${var.deploy_env}"
    Environment = "${var.deploy_env}"
  }
}
