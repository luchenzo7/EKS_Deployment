terraform {
  backend "s3" {
    bucket         = "tc2-terraform-state-ll"
    key            = "tech-challenge-2/prod/terraform.tfstate"
    region         = "us-east-1" # or your region
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
