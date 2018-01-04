############ Bucket for static content

resource "aws_s3_bucket" "assets_bucket" {
  bucket        = "${var.aws_profile}-web-assets"
  acl           = "private"
  force_destroy = "${var.s3_bucket_force_destroy}"

  versioning {
    enabled = true
  }

  tags {
    Name = "${var.aws_profile}-web-assets"
  }
}

data "template_file" "web_iam_s3_role_policy" {
  template = "${file("templates/web_iam_s3_role_policy.json.tpl")}"

  vars {
    assets_bucket_name = "${aws_s3_bucket.assets_bucket.id}"
  }
}

resource "aws_iam_policy" "web_iam_s3_role_policy" {
  name   = "web_iam_s3_role_policy"
  policy = "${data.template_file.web_iam_s3_role_policy.rendered}"
}

resource "aws_iam_group_policy_attachment" "s3-policy-attach" {
  count      = "${length(var.iam_dev_group_members) > 0 ? 1 : 0}"
  group      = "${aws_iam_group.devs.name}"
  policy_arn = "${aws_iam_policy.web_iam_s3_role_policy.arn}"
}

############ Logs bucket

resource "aws_s3_bucket" "logs_bucket" {
  bucket        = "${var.aws_profile}-logs"
  acl           = "private"
  policy        = "${data.template_file.web_iam_s3_logs_policy.rendered}"
  force_destroy = "${var.s3_bucket_force_destroy}"

  versioning {
    enabled = false
  }

  tags {
    Name = "${var.aws_profile}-logs"
  }
}

data "template_file" "web_iam_s3_logs_policy" {
  template = "${file("templates/web_iam_s3_logs_policy.json.tpl")}"

  vars {
    bucket_name    = "${var.aws_profile}-logs"
    aws_account_id = "${data.aws_caller_identity.current.account_id}"
  }
}
