# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "devopsrg" {
    name     = var.rgname
    location = var.location

    tags = {
        environment = "Dev"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "devopsproject" {
    name                = "${var.prefix}-azvnet"
    address_space       = [var.addr_space]
    location            = var.location
    resource_group_name = azurerm_resource_group.devopsrg.name

    tags = {
        environment = "Dev"
    }
}

# Create subnet
resource "azurerm_subnet" "devopsproject" {
    name                 = "${var.prefix}-azsubnet"
    resource_group_name  = azurerm_resource_group.devopsrg.name
    virtual_network_name = azurerm_virtual_network.devopsproject.name
    address_prefixes       = [var.subnet_addr]
}

# Create public IPs
resource "azurerm_public_ip" "devopsproject" {
    count                        = var.vmcount
    name                         = "${var.prefix}-vm-publicip-${count.index}"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.devopsrg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Dev"
    }
}
resource "azurerm_public_ip" "lb" {
    name                         = "${var.prefix}-publicip-lb"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.devopsrg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Dev"
    }
}
# Create Network Security Group and rule
resource "azurerm_network_security_group" "devopsproject" {
    name                = "${var.prefix}-nsg"
    location            = var.location
    resource_group_name = azurerm_resource_group.devopsrg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Dev"
    }
}

# Create network interface
resource "azurerm_network_interface" "devopsproject" {
    count                     = var.vmcount 
    name                      = "${var.prefix}-nic-${count.index}"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.devopsrg.name

    ip_configuration {
        name                          = "NicIpConfig-${count.index}"
        subnet_id                     = azurerm_subnet.devopsproject.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.devopsproject.*.id, count.index)
    }

    tags = {
        environment = "Dev"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "devopsproject" {
    count                     = var.vmcount
    network_interface_id      = element(azurerm_network_interface.devopsproject.*.id, count.index)
    network_security_group_id = element(azurerm_network_security_group.devopsproject.*.id, count.index)
}
# Create load balancer 
resource "azurerm_lb" "devopsproject" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.devopsrg.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
  tags = {
        environment = "Dev"
  }  
}

resource "azurerm_lb_backend_address_pool" "devopsproject" {
  resource_group_name = azurerm_resource_group.devopsrg.name
  loadbalancer_id     = azurerm_lb.devopsproject.id
  name                = "BackEndAddressPool"
}
resource "azurerm_network_interface_backend_address_pool_association" "devopsproject" {
  count                   = var.vmcount
  network_interface_id    = element(azurerm_network_interface.devopsproject.*.id, count.index)
  ip_configuration_name   = "NicIpConfig-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.devopsproject.id
}
resource "azurerm_availability_set" "devopsproject" {
  name                = "${var.prefix}-availset"
  location            = azurerm_resource_group.devopsrg.location
  resource_group_name = azurerm_resource_group.devopsrg.name

  tags = {
    environment = "Dev"
  }
}
# Create (and display) an SSH key
resource "tls_private_key" "devops_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.devops_ssh.private_key_pem 
    sensitive = true
}
# Create virtual machine
resource "azurerm_linux_virtual_machine" "devopsproject" {
    count                 = var.vmcount
    name                  = "${var.prefix}-vm-${count.index}"
    location              = var.location
    resource_group_name   = azurerm_resource_group.devopsrg.name
    network_interface_ids = [element(azurerm_network_interface.devopsproject.*.id, count.index)]
    availability_set_id   = azurerm_availability_set.devopsproject.id
    size                  = var.vmsize

    os_disk {
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_id = var.pckimg

    computer_name  = "${var.prefix}-vm${count.index}"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.devops_ssh.public_key_openssh
    }

    tags = {
        environment = "Dev"
    }
}