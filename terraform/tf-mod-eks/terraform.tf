terraform {
  backend "s3" {
    bucket         = "howdevops-terraform-states"
    key            = "tf-mod-eks/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "howdevops-terraform-locks"
    encrypt        = true
  }
}