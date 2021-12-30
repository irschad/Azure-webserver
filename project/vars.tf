variable "prefix" {
  description = "Prefix used for resources in this project"
  default     = "udadevops"
}
variable "addr_space" {
  description = "Address space used by the virtual network"  
  default = "10.0.0.0/16"
}

variable "subnet_addr" {
  description = "Subnet address"
  default = "10.0.0.0/24"
}
variable "vmcount" {
  description = "Number of VMs to be created"
  default     = 2
}
variable "location" {
	description = "Azure region where resources will be created"
	default = "East US"
}
variable "rgname" {
	description = "Name of the resource group"
	default = "udacity-azure-rg"
}
variable "pckimg" {
    description = "Packer image in Azure"
    default = "/subscriptions/5b6be972-dd9c-45b0-a45c-d8a14b55633c/resourceGroups/MYRESOURCEGROUP/providers/Microsoft.Compute/images/myPackerImage"
}
variable "vmsize" {
  default = "Standard_DS1_v2"
  description = "Size to be used for VMs"
}