variable "aws_profile" {
  description = "Name for aws account (from ~/.aws/credentials)"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "iam_admin_group_members" {
  type        = "list"
  description = "IAM users to make as member of admins group"
  default     = []
}

variable "iam_users" {
  type        = "list"
  description = "List of iam users to create"
  default     = []
}

variable "iam_dev_group_members" {
  type        = "list"
  description = "IAM users to make as member of devs group"
  default     = []
}

variable "state_bucket_suffix" {
  description = "Suffix for the s3 bucket used to store TF state"
  default     = "terraform-state"
}

variable "s3_bucket_force_destroy" {
  # See https://github.com/terraform-providers/terraform-provider-aws/issues/208
  description = "Force delete s3 buckets along with all contents (bool)"
  default     = true
}

variable "openshift_registry_user" {
  description = "User for openshift registry container to store backend in s3"
  default     = "openshift_registry"
}

variable "openshift_registry_group" {
  description = "Group for openshift registry container to store backend in s3"
  default     = "s3_full_access"
}

variable "org_id" {
  default = "The name of the organisation, used as a prefix"
  default = ""
}

variable "external_domain" {
  description = "External domain name"
  default     = "example-domain.com"
}

variable "private_domain" {
  description = "Name of private DNS zone"
  default     = "example-domain.test"
}

variable "mx_records" {
  description = "MX records for domains we create"

  default = [
    "1 ASPMX.L.GOOGLE.COM.",
    "5 ALT1.ASPMX.L.GOOGLE.COM.",
    "5 ALT2.ASPMX.L.GOOGLE.COM.",
    "10 ASPMX2.GOOGLEMAIL.COM.",
    "10 ASPMX3.GOOGLEMAIL.COM.",
  ]
}

variable "peer_res_class" {
  description = "Other DEPLOY_ENV's RES_CLASS to peer with"
  default     = ""
}

variable "peer_deploy_env" {
  description = "Other DEPLOY_ENVs to peer with (list)"
  default     = ""
}

variable "trusted_pgp_user" {
  # Use YOUR OWN here, this one is just an example from kernel.org
  description = "PGP key holder that can decrypt PGP secrets output by this terraform script"
  default     = "38DBBDC86092693E"
}

variable "iam_user_force_destroy" {
  # See https://github.com/terraform-providers/terraform-provider-aws/issues/208
  description = "If set to true, will force destroy users"
  default     = true
}

variable "iam_billing_group_members" {
  type        = "list"
  description = "IAM users to created as Billing Admins"
  default     = []
}

variable "iam_route53_group_members" {
  type        = "list"
  description = "IAM users to created as Route53 Admins"
  default     = []
}
