output "firewall_public_ip" {
  description = "The public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}