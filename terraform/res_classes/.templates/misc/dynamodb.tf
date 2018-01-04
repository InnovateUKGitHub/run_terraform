resource "aws_dynamodb_table" "credstash" {
  name           = "${var.deploy_env}-secrets"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "name"
  range_key      = "version"

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "version"
    type = "S"
  }
}
