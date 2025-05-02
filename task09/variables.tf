variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "vnet_name" {
  type        = string
  description = "Name of the existing virtual network"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space of the existing VNet"
}

variable "aks_subnet_name" {
  type        = string
  description = "Name of the existing AKS subnet"
}

variable "aks_subnet_address_space" {
  type        = string
  description = "Address space of the AKS subnet"
}

variable "aks_loadbalancer_ip" {
  type        = string
  description = "Public IP of AKS load balancer"
}

variable "environment" {
  type        = string
  description = "Environment tag value"
}

variable "project_prefix" {
  type        = string
  description = "Prefix for resource naming"
}