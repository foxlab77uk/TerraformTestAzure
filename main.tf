terraform {
  backend "azurerm" {
    resource_group_name  = "foxlab-infra"
    storage_account_name = "foxlabtstate"
    container_name       = "tstate"
    key                  = "jzK/iOux1xZ4cNiSLTjI73Hka/qcBitpdECObruUABu7bmi8WO2NL0jeBnd9zEDnWrZsXF/6WX9BbYBgCLwezw=="
  }

  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source  = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - foxlab-RG
resource "azurerm_resource_group" "rg" {
  name     = "foxlab-app01"
  location = "UK South"
}
# Create our Virtual Network - foxlab-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "foxlabvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - foxlabsa
resource "azurerm_storage_account" "foxlabsa" {
  name                     = "foxlabsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "foxlabenv1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "foxlabvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - foxlab-VM01
resource "azurerm_virtual_machine" "foxlabvm01" {
  name                  = "foxlabvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "foxlabvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "foxlabvm01"
    admin_username = "foxlab"
    admin_password = "Password123$"
  }
  os_profile_windows_config {
  }
}
