# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
  subscription_id = "d945d7dd-ab0f-4f97-b41e-01d16e5f80fd"
  client_id       = "ae2f00aa-3604-4864-9997-7730185e8b15"
  client_secret   = "OIC8Q~Js9WWAK0iPwLqx0vsEkc9p.YZaYGM9_aLR"

  #lVX8Q~3BUN.QxuUv-wsufYJhmS40TwMkhnBddcsC
  #OIC8Q~Js9WWAK0iPwLqx0vsEkc9p.YZaYGM9_aLR
  tenant_id = "abca0c90-dd14-4127-9866-81cf36e2cf37"

}

resource "azurerm_resource_group" "TFuser-RG1" {
  name     = "TFuser-RG00"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "TFuser-VNET01"
  location            = azurerm_resource_group.TFuser-RG1.location
  resource_group_name = azurerm_resource_group.TFuser-RG1.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vnet01-subnet02" {
  name                 = "TFuser-VNET01-SNET02"
  resource_group_name  = azurerm_resource_group.TFuser-RG1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/26"]
}

#---------->1
# NSG Creation

resource "azurerm_network_security_group" "vnet01-nsg01" {
  name                = "TFuser-VNET01-NSG01"
  location            = azurerm_resource_group.TFuser-RG1.location
  resource_group_name = azurerm_resource_group.TFuser-RG1.name
}

#---------->2
# Network Interface Creation

resource "azurerm_network_interface" "vnet01-nsg01-ni01" {
  name                = "TFuser-VNET01-NI01"
  location            = azurerm_resource_group.TFuser-RG1.location
  resource_group_name = azurerm_resource_group.TFuser-RG1.name

  ip_configuration {
    name                          = "vnet01-ipconfig"
    subnet_id                     = azurerm_subnet.vnet01-subnet02.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "vnet01-ipconfig2"
    subnet_id                     = azurerm_subnet.vnet01-subnet02.id
    #private_ip_address_allocation = "Dynamic"
    #private_ip_address_allocation = azurerm_azurerm_public_ip.TFuser-VNET01-SNET02.name
  }
}

#---------->3
# NetworkInterface Security Group Association

resource "azurerm_network_interface_security_group_association" "vnet01-nisga01" {
  network_interface_id      = azurerm_network_interface.vnet01-nsg01-ni01.id
  network_security_group_id = azurerm_network_security_group.vnet01-nsg01.id
}

#---------->4
# NSG Association to Subnets

resource "azurerm_subnet_network_security_group_association" "nsgA01" {
  subnet_id                 = azurerm_subnet.vnet01-subnet02.id
  network_security_group_id = azurerm_network_security_group.vnet01-nsg01.id
}

#---------->5
#vm creation 

resource "azurerm_windows_virtual_machine" "vm1" {
  name                  = "TFUSERVMWIN01"
  resource_group_name   = azurerm_resource_group.TFuser-RG1.name
  location              = azurerm_resource_group.TFuser-RG1.location
  network_interface_ids = [azurerm_network_interface.vnet01-nsg01-ni01.id]
  admin_username        = "Bhanu"
  admin_password        = "Bhanu@12345"
  size                  = "Standard_B1s"
  public_ip             = azurerm_azurerm_public_ip.name

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_security_rule" "nsgrule1" {
  name                        = "nsgrule01"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.TFuser-RG1.name
  network_security_group_name = azurerm_network_security_group.vnet01-nsg01.name
}

resource "azurerm_public_ip" "pubip1" {
  name                = "TFuser-VNET01-SNET02"
  resource_group_name = azurerm_resource_group.TFuser-RG1.name
  location            = azurerm_resource_group.TFuser-RG1.location
  allocation_method   = "Dynamic"
}
