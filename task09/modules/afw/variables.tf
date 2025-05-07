variable "resource_group_name" {
  description = "Existing resource group name"
  type        = string
}

variable "location" {
  description = "Azure region (must use exact format)"
  type        = string
}

variable "vnet_name" {
  description = "Existing VNet name"
  type        = string
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
}

variable "aks_subnet_name" {
  description = "AKS subnet name"
  type        = string
}

variable "aks_subnet_address_space" {
  description = "AKS subnet CIDR"
  type        = string
}

variable "aks_loadbalancer_ip" {
  description = "AKS load balancer IP"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
}

variable "project_prefix" {
  description = "Naming prefix"
  type        = string
}