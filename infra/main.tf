terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    // TODO: configure infrastructure details in env vars.
    bucket         = "footystats-terraform-state" // Pre-existing bucket to store tfstate
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "footystats-terraform" // Pre-existing Dynamo DB for state locking https://www.terraform.io/language/state/locking
  }
}

provider "aws" {
  region  = "ap-southeast-2"
}

resource "aws_ecr_repository" "footystats_web_ecr_repo" {
  name           = "footystats_web_ecr_repo"
}
