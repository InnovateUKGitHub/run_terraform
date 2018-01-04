data "terraform_remote_state" "peer" {
  count   = "${length(var.peer_deploy_env) > 0 && length(var.peer_res_class) > 0 ? 1 : 0}"
  backend = "s3"

  config {
    bucket = "${var.aws_profile}-${var.state_bucket_suffix}"
    key    = "${var.peer_deploy_env}-${var.peer_res_class}.tfstate"
  }
}

#### DELME - This is just an example of how we may conditionally create objects
#### such as peering and routes only when the peer environment is defined.
#
# resource "aws_route53_record" "foo" {
#   count   = "${length(var.peer_deploy_env) > 0 ? 1 : 0}"
#   zone_id = "${module.route53.deploy_env_private_domain_zone_id}"
#   name    = "foobar"
#   type    = "CNAME"
#   ttl     = "300"
#   records = ["${data.terraform_remote_state.peer.sample_output}"]
# }

