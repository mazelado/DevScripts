#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Matt Daleo (mazelado)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://getwud.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "wud" "getwud/wud" "tarball"

msg_info "Building WUD"
cd /opt/wud/app
$STD npm ci --include=dev --omit=optional --no-audit --no-fund
$STD npm run build
$STD npm prune --omit=dev
cd /opt/wud/ui
$STD npm ci --include=dev --omit=optional --no-audit --no-fund
$STD npm run build
cp -r /opt/wud/ui/dist /opt/wud/app/ui
msg_ok "Built WUD"

msg_info "Configuring WUD"
mkdir -p /opt/wud/data
var_admin_user="${var_admin_user:-admin}"
var_admin_password="${var_admin_password:-$(random_password)}"
cat <<EOF >/opt/wud/.env
WUD_STORE_PATH=/opt/wud/data
WUD_AUTH_ADMIN_USER=${var_admin_user}
WUD_AUTH_ADMIN_PASSWORD=${var_admin_password}
EOF
chmod 600 /opt/wud/.env
msg_ok "Configured WUD"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wud.service
[Unit]
Description=WUD (What's Up Docker)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wud/app
Environment=NODE_ENV=production
EnvironmentFile=/opt/wud/.env
ExecStart=/usr/bin/node dist/index
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wud
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
