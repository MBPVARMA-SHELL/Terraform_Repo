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
  tenant_id = "abca0c90-dd14-4127-9866-81cf36e2cf37"  
}

resource "azurerm_resource_group" "rg" {
    name = "${var.rgname}"
    location="${var.rglocation}"
}

resource "azurerm_virtual_network" "vnet1" {
    name    =   "${var.prefix}-${azurerm_resource_group.rg.name}-VNET1"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location =  "${azurerm_resource_group.rg.location}"
    address_space = ["${var.vnet_cicd_prefix}"]  
}

resource "azurerm_subnet" "subnet1" {
    name =  "${azurerm_virtual_network.vnet1.name}-SUBNET1"
    virtual_network_name =  "${azurerm_virtual_network.vnet1.name}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    address_prefixes = ["${var.subnet1_cidr_prefix}"]
}

resource "azurerm_network_security_group" "nsg1" {
    name = "${var.prefix}-${azurerm_resource_group.rg.name}-NSG1"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location =  "${azurerm_resource_group.rg.location}"
}

resource "azurerm_network_security_rule" "ssh" {
    name = "ssh-rule"
    resource_group_name ="${azurerm_resource_group.rg.name}"
    network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
    priority = 1002
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix ="*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
    subnet_id = azurerm_subnet.subnet1.id
    network_security_group_id= azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
    name = "${var.prefix}-${azurerm_resource_group.rg.name}-NIC1"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location =  "${azurerm_resource_group.rg.location}"
    

    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.pubip1.id
    }
}

resource "azurerm_linux_virtual_machine" "LinuxVM1" {
    name                = "BHANULINUXVM01"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location =  "${azurerm_resource_group.rg.location}"
    size                = "Standard_F2"
    admin_username      = "adminuser"
    admin_password = "Bhanu@12345"
    network_interface_ids = [azurerm_network_interface.nic1.id]
    disable_password_authentication=false
    
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "latest"
    }
}

resource "azurerm_public_ip" "pubip1" {
  name                = "${var.prefix}-${azurerm_resource_group.rg.name}-PUBIP1"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location =  "${azurerm_resource_group.rg.location}"
  allocation_method   = "Dynamic" 
}