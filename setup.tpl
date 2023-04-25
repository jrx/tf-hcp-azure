#!/bin/bash
# NB this file will be executed as root by cloud-init.
# NB to troubleshoot the execution of this file, you can:
#      1. access the virtual machine boot diagnostics pane in the azure portal.
#      2. ssh into the virtual machine and execute:
#           * sudo journalctl
#           * sudo journalctl -u cloud-final
set -euxo pipefail

ip_address="$(ip addr show eth0 | perl -n -e'/ inet (\d+(\.\d+)+)/ && print $1')"

# install vault.
# NB execute `apt-cache madison vault` to known the available versions.
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get install -y "vault-enterprise=${vault_version}" jq

systemctl disable vault
systemctl stop vault

# cat >/etc/profile.d/vault.sh <<'EOF'
# export VAULT_ADDR=http://127.0.0.1:8200
# export VAULT_SKIP_VERIFY=true
# EOF