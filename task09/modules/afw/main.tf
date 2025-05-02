# Create Azure Firewall Subnet
resource "azurerm_subnet" "firewall" {
  name                 = local.firewall_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [local.firewall_subnet_prefix]
}

# Create Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = local.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.default_tags
}

# Create Azure Firewall
resource "azurerm_firewall" "this" {
  name                = local.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.default_tags
}

# Create Route Table
resource "azurerm_route_table" "aks" {
  name                = local.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "aks-egress"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }

  tags = local.default_tags
}

# Associate Route Table with AKS Subnet
resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${var.aks_subnet_name}"
  route_table_id = azurerm_route_table.aks.id
}

# Application Rule Collection for AKS egress
resource "azurerm_firewall_application_rule_collection" "aks_egress" {
  name                = local.app_rule_collection_name
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-required-aks-fqdn"

    source_addresses = [var.aks_subnet_address_space]

    target_fqdns = [
      "*.hcp.eastus.azmk8s.io",
      "mcr.microsoft.com",
      "*.cdn.mscr.io",
      "management.azure.com",
      "login.microsoftonline.com",
      "packages.microsoft.com",
      "acs-mirror.azureedge.net",
      "*.blob.core.windows.net",
      "*.azurecr.io"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}

# Network Rule Collection for AKS egress
resource "azurerm_firewall_network_rule_collection" "aks_egress" {
  name                = local.net_rule_collection_name
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"

  rule {
    name = "allow-aks-dns"

    source_addresses = [var.aks_subnet_address_space]

    destination_ports = ["53"]
    destination_addresses = [
      "8.8.8.8",
      "8.8.4.4",
      "168.63.129.16" # Azure DNS
    ]
    protocols = ["UDP", "TCP"]
  }

  rule {
    name = "allow-aks-time"

    source_addresses      = [var.aks_subnet_address_space]
    destination_ports     = ["123"]
    destination_addresses = ["*"]
    protocols             = ["UDP"]
  }

  rule {
    name = "allow-azure-services"

    source_addresses      = [var.aks_subnet_address_space]
    destination_ports     = ["443", "80"]
    destination_addresses = ["AzureCloud"]
    protocols             = ["TCP"]
  }
}

# NAT Rule Collection for AKS ingress
resource "azurerm_firewall_nat_rule_collection" "aks_ingress" {
  name                = local.nat_rule_collection_name
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 300
  action              = "Dnat"

  rule {
    name = "nginx-http-ingress"

    source_addresses      = ["*"]
    destination_addresses = [azurerm_public_ip.firewall.ip_address]
    destination_ports     = ["80"]
    translated_address    = var.aks_loadbalancer_ip
    translated_port       = "80"

    protocols = ["TCP"]
  }

  rule {
    name = "nginx-https-ingress"

    source_addresses      = ["*"]
    destination_addresses = [azurerm_public_ip.firewall.ip_address]
    destination_ports     = ["443"]
    translated_address    = var.aks_loadbalancer_ip
    translated_port       = "443"

    protocols = ["TCP"]
  }
}

data "azurerm_subscription" "current" {}