variable "aws_profile" {
  description = "AWS profile/account name"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "org_id" {
  description = "Short acronym for this organisation"
  default     = ""
}

variable "res_class" {
  description = "Resource Class"
}

variable "deploy_env" {
  description = "Name for deployment environment"
}

variable "state_bucket_suffix" {
  description = "Suffix for the s3 bucket used to store TF state"
  default     = "terraform-state"
}

variable "key_name" {
  description = "Key name for deployment"
}

variable "public_key_path" {
  description = "Public key path"
  default     = "~/.ssh/id_rsa.pub"
}

variable "creator" {
  description = "Creator of the infrastructure"
  default     = "Terraform"
}

variable "vpc_cidr" {
  description = "VPC top level CIDR"
  default     = "10.10.0.0/16"
}

variable "vpc_private_subnets" {
  description = "VPC private subnets (list)"
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "vpc_public_subnets" {
  description = "VPC public subnets (list)"
  default     = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
}

variable "vpc_database_subnets" {
  description = "VPC database subnets (list)"
  default     = ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"]
}

variable "vpc_elasticache_subnets" {
  description = "VPC elasticache subnets (list)"
  default     = ["10.10.31.0/24", "10.10.32.0/24", "10.10.33.0/24"]
}

variable "mgmt-whitelist-cidrs" {
  description = "Whitelist of CIDRs for ssh access (list)"
  default     = ["0.0.0.0/0"]
}

variable "peer_res_class" {
  description = "Other DEPLOY_ENV's RES_CLASS to peer with"
  default     = ""
}

variable "peer_deploy_env" {
  description = "Other DEPLOY_ENVs to peer with (list)"
  default     = ""
}

variable "external_domain" {
  description = "External domain name"
  default     = "example-domain.com"
}

variable "private_domain" {
  description = "Name of private DNS zone"
  default     = "example-domain.test"
}
