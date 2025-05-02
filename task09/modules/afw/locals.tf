locals {
  firewall_subnet_name   = "AzureFirewallSubnet"
  firewall_subnet_prefix = cidrsubnet(var.vnet_address_space, 8, 1) # 10.0.1.0/24

  # Resource names
  firewall_name    = "${var.project_prefix}-${var.environment}-afw"
  public_ip_name   = "${var.project_prefix}-${var.environment}-afw-pip"
  route_table_name = "${var.project_prefix}-${var.environment}-rt"

  # Rule collection names
  app_rule_collection_name = "aks-egress-rules"
  net_rule_collection_name = "aks-egress-network-rules"
  nat_rule_collection_name = "aks-ingress-rules"

  # Required tags
  default_tags = {
    environment = var.environment
    managedBy   = "terraform"
  }
}