locals {
  firewall_subnet_name   = "AzureFirewallSubnet"
  firewall_subnet_prefix = cidrsubnet(var.vnet_address_space, 8, 1)

  firewall_name    = "${var.project_prefix}-${var.environment}-afw"
  public_ip_name   = "${var.project_prefix}-${var.environment}-afw-pip"
  route_table_name = "${var.project_prefix}-${var.environment}-rt"

  app_rule_collection_name = "aks-egress-app-rules"
  net_rule_collection_name = "aks-egress-net-rules"
  nat_rule_collection_name = "aks-ingress-nat-rules"

  default_tags = {
    environment = var.environment
    managedBy   = "terraform"
  }
}