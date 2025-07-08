terraform {
  backend "s3" {
    bucket       = "devops-course-vasilii"
    key          = "tf-state/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-2"
    encrypt      = "true"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "dev"
      Task        = "task-3"
    }
  }
}

locals {
  bastion_cidr = var.public_subnet_cidrs[0]
}