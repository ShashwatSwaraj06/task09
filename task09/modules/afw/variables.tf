variable "resource_group_name" {
  description = "The name of the existing resource group where resources will be deployed"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
}

variable "vnet_name" {
  description = "The name of the existing virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space of the existing virtual network"
  type        = string
}

variable "aks_subnet_name" {
  description = "The name of the existing AKS subnet"
  type        = string
}

variable "aks_subnet_address_space" {
  description = "The address space of the existing AKS subnet"
  type        = string
}

variable "aks_loadbalancer_ip" {
  description = "The public IP address of the existing AKS load balancer"
  type        = string
}

variable "environment" {
  description = "The environment tag to apply to resources"
  type        = string
  default     = "mod9"
}

variable "project_prefix" {
  description = "The naming prefix for all resources"
  type        = string
  default     = "cmtr-57d8b090"
}