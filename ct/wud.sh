#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Matt Daleo (mazelado)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://getwud.app/

APP="WUD"
var_tags="${var_tags:-docker;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified

export var_admin_user="${var_admin_user:-}"
export var_admin_password="${var_admin_password:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/wud ]]; then
    msg_error "No WUD Installation Found!"
    exit
  fi

  if check_for_gh_release "wud" "getwud/wud"; then
    NODE_VERSION="24" setup_nodejs

    msg_info "Stopping WUD"
    systemctl stop wud
    msg_ok "Stopped WUD"

    create_backup /opt/wud/.env

    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="data" fetch_and_deploy_gh_release "wud" "getwud/wud" "tarball"

    restore_backup

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

    msg_info "Starting WUD"
    systemctl start wud
    msg_ok "Started WUD"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
