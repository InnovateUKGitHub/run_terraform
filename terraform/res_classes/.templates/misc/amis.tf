module "ecs" {
  source  = "Smartbrood/data-ami/aws"
  version = "0.1.0"

  distribution = "ecs"
}
