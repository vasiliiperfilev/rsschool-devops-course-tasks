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