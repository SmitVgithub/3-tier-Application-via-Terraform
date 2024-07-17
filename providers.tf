# providers.tf
provider "aws" {
  region  = var.aws_region
  version = "5.55.0"
}

terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
  }

  backend "s3" {
    bucket         = "backend-tf-cirrops"
    key            = "state/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "backend-tf-lockid"
  }   
}
