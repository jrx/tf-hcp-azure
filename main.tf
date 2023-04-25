# see https://github.com/terraform-providers/terraform-provider-azurerm
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "vault" {
  name     = "${var.environment}-hcp-rg"
  location = var.location

  tags = {
    environment = var.environment
  }
}

