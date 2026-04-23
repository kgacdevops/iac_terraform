terraform {
  backend "s3" {
    bucket         = "{TFSTATE_BUCKET_NAME}"
    key            = "insideout/terraform.tfstate"
    region         = "{REGION}"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}