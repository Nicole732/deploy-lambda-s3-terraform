terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "mentorship-state-nic"
    key          = "terraform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    #dynamodb_table = "tfstate-lock"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "iamadmin-gen"
}
