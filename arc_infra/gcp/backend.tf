terraform {
  backend "gcs" {
    bucket = "{TFSTATE_BUCKET_NAME}"
    prefix = "terraform/state"
  }
}