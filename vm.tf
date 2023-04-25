
resource "random_id" "tf_random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.vault.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "tf_storageaccount" {
  name                     = "sa${random_id.name.hex}"
  resource_group_name      = azurerm_resource_group.vault.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "${var.environment}-${random_id.name.hex}"
  }
}

data "template_file" "setup" {
  template = file("${path.module}/setup.tpl")

  vars = {
    vault_version = var.vault_version
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "tf_vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.vault.name
  network_interface_ids = [azurerm_network_interface.tf_nic.id]
  size                  = "Standard_DS1_v2"
  custom_data           = base64encode(data.template_file.setup.rendered)
  computer_name         = var.vm_name
  admin_username        = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.public_key
  }

  # NB this identity is used in the example /tmp/azure_auth.sh file.
  #    vault is actually using the vault service principal.
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "${var.vm_name}-os"
    caching              = "ReadWrite" # TODO is this safe?
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.tf_storageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "${var.environment}-${random_id.name.hex}"
  }
}

data "azurerm_public_ip" "tf_publicip" {
  name                = azurerm_public_ip.tf_publicip.name
  resource_group_name = azurerm_linux_virtual_machine.tf_vm.resource_group_name
}

output "ip" {
  value = data.azurerm_public_ip.tf_publicip.ip_address
}

output "ssh-addr" {
  value = <<SSH

    Connect to your virtual machine via SSH:

    $ ssh azureuser@${data.azurerm_public_ip.tf_publicip.ip_address}


SSH
}
