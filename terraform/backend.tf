terraform {
  backend "s3" {
    bucket         = "calmroot-terraform-state"
    key            = "calmroot/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "calmroot-terraform-locks"
    encrypt        = true
  }
}
