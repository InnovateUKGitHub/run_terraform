variable "aws_profile" {
  description = "Name for aws account (from ~/.aws/credentials)"
}

variable "deploy_env" {
  description = "Name for deployment environment"
}

variable "vpc-id" {
  description = "VPC in which to create route53 zones"
}

variable "org_id" {
  description = "Short acronym for this organisation"
  default     = ""
}

variable "private-domain" {
  description = "Name of private DNS zone"
  default     = "example-domain.test"
}

variable "public-domain" {
  description = "Name of public DNS zone"
  default     = "example-domain.com"
}

variable "elb-bastion-dns-name" {
  description = "Target for bastion CNAME"
}

variable "force_destroy_private_hosted_zone" {
  description = "Set to true to force destruction of the private hosted route53 zone"
  default     = false
}

variable "force_destroy_public_hosted_zone" {
  description = "Set to true to force destruction of the public hosted route53 zone"
  default     = false
}
