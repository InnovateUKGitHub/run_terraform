# Credstash key
resource "aws_kms_key" "credstash" {
  description             = "KMS key for credstash"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "credstash" {
  name          = "alias/credstash"
  target_key_id = "${aws_kms_key.credstash.key_id}"
}

# EBS key
resource "aws_kms_key" "ebs" {
  description             = "KMS key for ebs"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOT
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/ebs"
  target_key_id = "${aws_kms_key.ebs.key_id}"
}

# Cloudtrail KMS Key
resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for cloudtrail"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Id": "Key policy created for CloudTrail",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudTrail to encrypt logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:GenerateDataKey*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
        }
      }
    },
    {
      "Sid": "Allow CloudTrail to describe key",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:DescribeKey",
      "Resource": "*"
    }
  ]
}
EOT
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail"
  target_key_id = "${aws_kms_key.cloudtrail.key_id}"
}
