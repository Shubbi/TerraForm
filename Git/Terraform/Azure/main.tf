#Ideally we should create multiple .tf files for manageability
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.24.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = ""
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""

  features {}
}

variable "storage_account_name" {
    type = string    
    description = "Please enter the storage account name"  
}

locals {
  resource_group = "app_grp"
  location = "eastus"
}

#Not sure how to check if the resource already exists, and if yes ignore
resource "azurerm_resource_group" "app_grp" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_storage_account" "storage_account" {
  #Ideally I need to use   
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.app_grp.name
  location                        = azurerm_resource_group.app_grp.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true

  tags = {
    environment = "staging"
  }

  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_storage_container" "vishaldata" {
  name                  = "vishaldata"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
  depends_on = [
    azurerm_storage_account.storage_account
  ]
}

resource "azurerm_storage_blob" "helloworld" {
  name                   = "helloworld.txt"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.vishaldata.name
  type                   = "Block"
  source                 = "helloworld.txt"
  depends_on = [
    azurerm_storage_container.vishaldata
  ]
}