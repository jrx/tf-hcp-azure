# Vault

output "vault_public_url" {
  value = hcp_vault_cluster.vault_hcp.*.vault_public_endpoint_url
}

output "vault_private_url" {
  value = hcp_vault_cluster.vault_hcp.*.vault_private_endpoint_url
}

output "vault_root_token" {
  value     = hcp_vault_cluster_admin_token.token.*.token
  sensitive = true
}