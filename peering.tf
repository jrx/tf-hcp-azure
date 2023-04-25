resource "random_id" "name" {
  byte_length = 4
}

resource "azurerm_virtual_network" "tf_network" {
  name                = "network-${random_id.name.hex}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name

  tags = {
    environment = "${var.environment}-${random_id.name.hex}"
  }
}

resource "azurerm_subnet" "tf_subnet" {
  name                 = "subnet-${random_id.name.hex}"
  resource_group_name  = azurerm_resource_group.vault.name
  virtual_network_name = azurerm_virtual_network.tf_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "tf_publicip" {
  name                = "ip-${random_id.name.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "${var.environment}-${random_id.name.hex}"
  }
}

locals {
  hvn_dir = "172.26.16.0/20"
}

resource "azurerm_network_security_group" "tf_nsg" {
  name                = "nsg-${random_id.name.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name

  # SSH

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Legacy

  security_rule {
    name                       = "Vault"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HCP Consul
  ## Create inbound rules

  security_rule {
    name                       = "ConsulServerInbound"
    priority                   = 400
    source_port_range          = "*"
    source_address_prefix      = local.hvn_dir
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "8301"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
  }



  security_rule {
    name                       = "ConsulClientInbound"
    priority                   = 401
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "8301"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
  }

  ## Create outbound rules


  security_rule {
    name                       = "ConsulServerOutbound"
    priority                   = 400
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = local.hvn_dir
    destination_port_range     = "8300-8301"
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
  }

  security_rule {
    name                       = "ConsulClientOutbound"
    priority                   = 401
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "8301"
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
  }

  security_rule {
    name                       = "HTTPOutbound"
    priority                   = 402
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = local.hvn_dir
    destination_port_range     = "80"
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
  }

  security_rule {
    name                       = "HTTPSOutbound"
    priority                   = 403
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = local.hvn_dir
    destination_port_range     = "443"
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
  }

  security_rule {
    name                       = "ConsulServerOutboundGRPC"
    priority                   = 404
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = local.hvn_dir
    destination_port_range     = "8502"
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
  }

  # HCP Vault

  security_rule {
    name                       = "VaultServerOutbound"
    priority                   = 410
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = local.hvn_dir
    destination_port_range     = "8200"
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
  }

  tags = {
    environment = "${var.environment}-${random_id.name.hex}"
  }
}

resource "azurerm_network_interface" "tf_nic" {
  name                = "nic-${random_id.name.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name

  ip_configuration {
    name                          = "nic-${random_id.name.hex}"
    subnet_id                     = azurerm_subnet.tf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_publicip.id
  }

  tags = {
    environment = "${var.environment}-${random_id.name.hex}"
  }
}

resource "azurerm_network_interface_security_group_association" "tf_nisga" {
  network_interface_id      = azurerm_network_interface.tf_nic.id
  network_security_group_id = azurerm_network_security_group.tf_nsg.id
}

## HCP Peering

locals {
  application_id = "52512bbe-4923-4ac7-be7c-d8d2044b820a"
  role_def_name  = join("-", ["hcp-hvn-peering-access", local.application_id])
  vnet_id        = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.vault.name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.tf_network.name}"
}

resource "azuread_service_principal" "principal" {
  application_id = local.application_id
}

resource "azurerm_role_definition" "definition" {
  name  = local.role_def_name
  scope = local.vnet_id

  assignable_scopes = [
    local.vnet_id
  ]

  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/peer/action",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write"
    ]
  }
}

resource "azurerm_role_assignment" "role_assignment" {
  principal_id       = azuread_service_principal.principal.id
  role_definition_id = azurerm_role_definition.definition.role_definition_resource_id
  scope              = local.vnet_id
}