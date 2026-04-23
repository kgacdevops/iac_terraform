terraform {
  backend "s3" {
    bucket         = "{TFSTATE_BUCKET_NAME}"
    key            = "arc/terraform.tfstate"
    region         = "{REGION}"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}