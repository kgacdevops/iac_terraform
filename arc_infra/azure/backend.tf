terraform {
  backend "azurerm" {
    resource_group_name  = "{TFSTATE_RG_NAME}"
    storage_account_name = "{TFSTATE_STORAGE_ACCT}"
    container_name       = "{TFSTATE_BUCKET_NAME}"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}