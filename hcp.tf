provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

resource "hcp_hvn" "example_hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
  cidr_block     = var.cidr_block
}

resource "hcp_vault_cluster" "vault_hcp" {
  count           = (var.vault_enabled == true ? 1 : 0)
  hvn_id          = hcp_hvn.example_hvn.hvn_id
  cluster_id      = var.vault_cluster_id
  tier            = "plus_small"
  public_endpoint = var.vault_public_endpoint
  #min_vault_version = var.min_vault_version
  #major_version_upgrade_config {
  #  upgrade_type = "MANUAL"
  #}
}

resource "hcp_vault_cluster_admin_token" "token" {
  count      = (var.vault_enabled == true ? 1 : 0)
  cluster_id = hcp_vault_cluster.vault_hcp[count.index].cluster_id
}