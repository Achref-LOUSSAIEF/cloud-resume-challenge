terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  
    }
  }
}

provider "aws" {
  region = "eu-north-1"  
}
resource "aws_s3_bucket" "resume_bucket" {
  bucket = "achref-cloud-resume-challenge"

  tags = {
    project = "cloud-resume-challenge"
  }
}