#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: summoningpixels
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://getarcane.app/

APP="Arcane"
var_tags="${var_tags:-docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  [[ -d /opt/arcane ]] || {
    msg_error "No ${APP} Installation Found!"
    exit 1
  }

  msg_info "Updating Arcane"
  COMPOSE_FILE=$(find /opt/arcane -maxdepth 1 -type f -name 'compose.yaml' ! -name '.env' | head -n1)
  if [[ -z "$COMPOSE_FILE" ]]; then
    msg_error "No valid compose file found in /opt/arcane!"
    exit 1
  fi
  COMPOSE_BASENAME=$(basename "$COMPOSE_FILE")

  BACKUP_FILE="/opt/arcane/${COMPOSE_BASENAME}.bak_$(date +%Y%m%d_%H%M%S)"
  cp "$COMPOSE_FILE" "$BACKUP_FILE" || {
    msg_error "Failed to create backup of ${COMPOSE_BASENAME}!"
    exit 1
  }
  GITHUB_URL="https://github.com/getarcaneapp/arcane/blob/main/docker/examples/compose.basic.yaml"
  if ! curl -fsSL "$GITHUB_URL" -o "$COMPOSE_FILE"; then
    msg_error "Failed to download ${COMPOSE_BASENAME} from GitHub!"
    mv "$BACKUP_FILE" "$COMPOSE_FILE"
    exit 1
  fi
  
  $STD docker compose -p arcane -f "$COMPOSE_FILE" --env-file /opt/arcane/.env pull
  $STD docker compose -p arcane -f "$COMPOSE_FILE" --env-file /opt/arcane/.env up -d
  msg_ok "Updated Arcane"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9120${CL}"
