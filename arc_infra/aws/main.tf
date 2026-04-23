module "s3" {
    source              = "./modules/s3"
    site_bucket_name    = var.site_bucket_name
}