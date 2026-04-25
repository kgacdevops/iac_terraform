module "frontend" {
    source              = "./modules/frontend"
    site_bucket_name    = var.site_bucket_name
}

module "backend" {
    source                      = "./modules/backend"
    prefix                      = var.prefix
    backend_pkg_path            = var.backend_pkg_path
    lambda_py_version           = var.lambda_py_version
    backend_lambda_handler      = var.backend_lambda_handler
    loaddb_pkg_path             = var.loaddb_pkg_path
    loaddb_lambda_handler       = var.loaddb_lambda_handler
}