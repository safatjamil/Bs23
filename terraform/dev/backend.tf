terraform {
  required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "5.56.1"
      }
    }
  
  backend "s3" {
    bucket = "<bucket_name>"
    key    = "<key>"
    region = "<region>"
  }
}
