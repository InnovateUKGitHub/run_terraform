# Generate an ssh keypair and store the result locally and in credstash
resource "null_resource" "deploy_ssh_key" {
  provisioner "local-exec" {
    command = "bash -x ../../bin/generate_ssh_keypair.sh deploy"
  }

  depends_on = ["aws_dynamodb_table.credstash"]
}

# Find or generate the ssh keypair contents
data "external" "deploy-public-key" {
  program = ["python", "../../bin/credstash_reader.py"]

  depends_on = [
    "null_resource.deploy_ssh_key",
  ]

  query = {
    key    = "deploy.ssh_key.public"
    table  = "${var.deploy_env}-secrets"
    region = "${var.aws_region}"
  }
}

# Create the AWS Keypair to use when creating the instances
resource "aws_key_pair" "auth" {
  key_name = "${var.deploy_env}-${var.key_name}"

  # get this from credstash
  public_key = "${trimspace(base64decode(lookup(data.external.deploy-public-key.result, "secret")))}"
}
