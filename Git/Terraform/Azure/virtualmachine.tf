resource "azurerm_public_ip" "publicip" {
  name                = "vishalSalPublicIP11"
  resource_group_name = local.resource_group
  location            = local.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }

  depends_on = [
    azurerm_virtual_network.app_vishal_network,
    azurerm_public_ip.publicip
  ]
}

resource "azurerm_windows_virtual_machine" "vishal_vm" {
  name                = "vishalvm"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_D2s_V3"
  admin_username      = ""
  #this is not a good practice , but ignoring for now, as for learning
  admin_password      = ""
  network_interface_ids = [
    azurerm_network_interface.app_interface.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface
  ]
}