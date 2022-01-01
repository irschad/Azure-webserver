# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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
  address_prefixes     = [var.subnet_addr]
}

# Create public IPs
resource "azurerm_public_ip" "devopsproject" {
  count               = var.vmcount
  name                = "${var.prefix}-vm-publicip-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.devopsrg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Dev"
  }
}
resource "azurerm_public_ip" "lb" {
  name                = "${var.prefix}-publicip-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.devopsrg.name
  allocation_method   = "Dynamic"

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
    priority                   = 101
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
# Create nsg rule to deny direct inbound access from the internet
resource "azurerm_network_security_rule" "DenyFromInternet" {
  name                        = "DenyVNetInboundFromInternet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.devopsrg.name
  network_security_group_name = azurerm_network_security_group.devopsproject.name
}
# Create network interface
resource "azurerm_network_interface" "devopsproject" {
  count               = var.vmcount
  name                = "${var.prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.devopsrg.name

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
# Create load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "devopsproject" {
  resource_group_name = azurerm_resource_group.devopsrg.name
  loadbalancer_id     = azurerm_lb.devopsproject.id
  name                = "BackEndAddressPool"
}
# Create network interface backend address pool association
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
# Create SSH key
resource "tls_private_key" "devops_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create managed disks
resource "azurerm_managed_disk" "mdisk" {
  count                = var.vmcount
  name                 = "${var.prefix}-mdisk-${count.index}"
  location             = azurerm_resource_group.devopsrg.location
  resource_group_name  = azurerm_resource_group.devopsrg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
  tags = {
    environment = "Dev"
  }
}
# Attach managed disks
resource "azurerm_virtual_machine_data_disk_attachment" "diskattach" {
  count              = var.vmcount
  managed_disk_id    = element(azurerm_managed_disk.mdisk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.devopsproject.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}
# Create virtual machines
resource "azurerm_linux_virtual_machine" "devopsproject" {
  count                 = var.vmcount
  name                  = "${var.prefix}-vm-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.devopsrg.name
  network_interface_ids = [element(azurerm_network_interface.devopsproject.*.id, count.index)]
  availability_set_id   = azurerm_availability_set.devopsproject.id
  size                  = var.vmsize

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.pckimg
  computer_name                   = "${var.prefix}-vm${count.index}"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.devops_ssh.public_key_openssh
  }

  tags = {
    environment = "Dev"
  }
}