# HCP 

variable "hcp_client_id" {}
variable "hcp_client_secret" {}
variable "hvn_id" {
  description = "The ID of the HCP HVN."
  type        = string
  default     = "hvn-azure-test"
}
variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "westeurope"
}
variable "cloud_provider" {
  description = "The cloud provider of the HCP HVN and Vault cluster."
  type        = string
  default     = "azure"
}
variable "cidr_block" {
  description = "The CIDR range of the HVN."
  type        = string
  default     = "172.26.16.0/20"
}

# Vault

variable "vault_enabled" {
  type        = bool
  description = "Deploy the HCP Vault"
  default     = false
}
variable "vault_cluster_id" {
  description = "The ID of the HCP Vault cluster."
  type        = string
  default     = "test-hcp-vault"
}
variable "min_vault_version" {
  description = "The minimum Vault version of the cluster."
  type        = string
  default     = ""
}
variable "vault_tier" {
  description = "Tier of the HCP Vault cluster."
  type        = string
  default     = "plus_small"
}
variable "vault_public_endpoint" {
  type        = bool
  description = "Deploy with Public DNS Endpoint."
  default     = false
}
variable "vault_proxy_endpoint" {
  type        = string
  description = "Deploy with Proxy Endpoint. Valid options are ENABLED, DISABLED."
  default     = "DISABLED"
}

# Azure

variable "tenant_id" {
  default = ""
}
variable "subscription_id" {
  default = ""
}
variable "location" {
  description = "Azure location where the Key Vault resource to be created"
  default     = "westeurope"
}
variable "environment" {
  default = "dev"
}
variable "vault_client_version" {
  # NB execute `apt-cache madison vault` to known the available versions.
  default = "1.9.4"
}
variable "public_key" {
  default = ""
}
variable "vm_name" {
  default = "demo-vm"
}