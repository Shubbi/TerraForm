resource "azurerm_virtual_network" "app_vishal_network" {
  name                = "app-vishal-network"
  location            = local.location
  resource_group_name = local.resource_group
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnetA"
    address_prefix = "10.0.1.0/24"
  }

  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

data "azurerm_subnet" "subnetA" {
    name = "subnetA"
    virtual_network_name = azurerm_virtual_network.app_vishal_network.name
    resource_group_name = local.resource_group
}