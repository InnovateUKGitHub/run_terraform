provider "terraform" {}

provider "aws" {
  version     = "~> 1.6"
  max_retries = "10"
}

provider "template" {
  version = "~> 1.0"
}

provider "external" {
  version = "~> 1.0"
}

provider "null" {
  version = "~> 1.0"
}
