variable "aws_profile" {
  description = "AWS profile/account name"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "res_class" {
  description = "Resource Class"
}

variable "deploy_env" {
  description = "Name for deployment environment"
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

variable "vpc_id" {
  description = "VPC ID of the environment to place the bastion"
}

variable "subnet_ids" {
  description = "VPC subnet IDs where bastion should live (list)"
  default     = []
}

variable "image_id" {
  description = "AMI to use for bastion"
}

variable "min_size" {
  description = "Minimum size of autoscaling group"
  default     = "1"
}

variable "max_size" {
  description = "Maximum size of autoscaling group"
  default     = "1"
}

variable "desired_capacity" {
  description = "Desired size of autoscaling group"
  default     = "1"
}

variable "cooldown" {
  description = "Cooldown period for autoscaling group"
  default     = "600"
}

variable "scale_down_desired_capacity" {
  description = "Desired size of autoscaling group when scaled down"
  default     = "0"
}

variable "scale_down_min_size" {
  description = "Minimum size of autoscaling group when scaled down"
  default     = "0"
}

variable "scale_up_cron" {
  description = "CRON style schedule for up"
  default     = "0 7 * * MON-FRI"
}

variable "scale_down_cron" {
  description = "CRON style schedule for down"
  default     = "0 0 * * SUN-SAT"
}

variable "mgmt-whitelist-cidrs" {
  description = "Whitelist of CIDRs for VPN server ssh access (list)"
  default     = ["0.0.0.0/0"]
}

variable "user_data" {
  description = "User data to use for instances"
  default     = ""
}
