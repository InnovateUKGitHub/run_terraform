resource "aws_cloudtrail" "this" {
  name                          = "${var.aws_profile}-cloudtrail"
  s3_bucket_name                = "${aws_s3_bucket.logs_bucket.id}"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = "${aws_kms_key.cloudtrail.arn}"
}
