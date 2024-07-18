terraform {
  required_version = "~> 1.1.2"

  backend "s3" {
    encrypt        = true
    bucket         = "mnaka-dev-remote-state"
    dynamodb_table = "mnaka-dev-terraform-locks-centralized"
    region         = "af-south-1"
    key            = "state/dev/terraform.tfstate"
  }
}