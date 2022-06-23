# Resource-1: Create firewall Subnet
resource "azurerm_subnet" "firewallsubnet" {
  name                 = "${azurerm_virtual_network.vnet.name}-${var.firewall_subnet_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.firewall_subnet_address  
}

# Resource-2: Create Network Security Group (NSG)
resource "azurerm_network_security_group" "firewall_subnet_nsg" {
  name                = "${azurerm_subnet.firewallsubnet.name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Resource-3: Associate NSG and Subnet
resource "azurerm_subnet_network_security_group_association" "firewall_subnet_nsg_associate" {
  depends_on = [ azurerm_network_security_rule.firewall_nsg_rule_inbound]  
  subnet_id                 = azurerm_subnet.firewallsubnet.id
  network_security_group_id = azurerm_network_security_group.firewall_subnet_nsg.id
}

# Resource-4: Create NSG Rules
## Locals Block for Security Rules
locals {
  firewall_inbound_ports_map = {
    "100" : "80", # If the key starts with a number, you must use the colon syntax ":" instead of "="
    "110" : "443",
    "120" : "8080",
    "130" : "22"
  } 
}
## NSG Inbound Rule for AppTier Subnets
resource "azurerm_network_security_rule" "firewall_nsg_rule_inbound" {
  for_each = local.firewall_inbound_ports_map
  name                        = "Rule-Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value 
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.firewall_subnet_nsg.name
}

# Resource-5: Create Public IP Address for Firewall
resource "azurerm_public_ip" "firewall-pip" {
  name                = var.firewall_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.firewall_pip_alloc
  sku                 = var.firewall_pip_sku
}

