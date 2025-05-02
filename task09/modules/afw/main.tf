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

# Application Rule Collection with Dynamic Blocks
resource "azurerm_firewall_application_rule_collection" "aks_egress" {
  name                = local.app_rule_collection_name
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  dynamic "rule" {
    for_each = {
      "allow-aks-egress" = {
        fqdns = [
          "*.hcp.${replace(var.location, " ", "")}.azmk8s.io",
          "mcr.microsoft.com",
          "*.cdn.mscr.io",
          "management.azure.com",
          "login.microsoftonline.com",
          "packages.microsoft.com",
          "acs-mirror.azureedge.net",
          "*.blob.core.windows.net",
          "*.azurecr.io"
        ]
      }
    }

    content {
      name             = rule.key
      source_addresses = [var.aks_subnet_address_space]
      target_fqdns     = rule.value.fqdns

      dynamic "protocol" {
        for_each = ["Http", "Https"]
        content {
          port = protocol.value == "Http" ? "80" : "443"
          type = protocol.value
        }
      }
    }
  }
}

# Network Rule Collection with Dynamic Blocks
resource "azurerm_firewall_network_rule_collection" "aks_egress" {
  name                = local.net_rule_collection_name
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"

  dynamic "rule" {
    for_each = {
      "dns" = {
        ports     = ["53"]
        addresses = ["8.8.8.8", "8.8.4.4", "168.63.129.16"]
        protocols = ["UDP", "TCP"]
      }
      "ntp" = {
        ports     = ["123"]
        addresses = ["*"]
        protocols = ["UDP"]
      }
      "azure-services" = {
        ports     = ["443", "80"]
        addresses = ["AzureCloud"]
        protocols = ["TCP"]
      }
    }

    content {
      name                  = "allow-${rule.key}"
      source_addresses      = [var.aks_subnet_address_space]
      destination_ports     = rule.value.ports
      destination_addresses = rule.value.addresses
      protocols             = rule.value.protocols
    }
  }
}

# NAT Rule Collection with Dynamic Blocks
resource "azurerm_firewall_nat_rule_collection" "aks_ingress" {
  name                = local.nat_rule_collection_name
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 300
  action              = "Dnat"

  dynamic "rule" {
    for_each = {
      "http"  = { port = "80" }
      "https" = { port = "443" }
    }

    content {
      name                  = "nginx-${rule.key}"
      source_addresses      = ["*"]
      destination_addresses = [azurerm_public_ip.firewall.ip_address]
      destination_ports     = [rule.value.port]
      translated_address    = var.aks_loadbalancer_ip
      translated_port       = rule.value.port
      protocols             = ["TCP"]
    }
  }
}

data "azurerm_subscription" "current" {}