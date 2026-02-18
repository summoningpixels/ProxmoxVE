#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: summoningpixels derp
# License: MIT | https://github.com/summoningpixels/ProxmoxVE/raw/main/LICENSE
# Source: https://getarcane.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup Docker Repository"
setup_deb822_repo \
  "docker" \
  "https://download.docker.com/linux/$(get_os_info id)/gpg" \
  "https://download.docker.com/linux/$(get_os_info id)" \
  "$(get_os_info codename)" \
  "stable" \
  "$(dpkg --print-architecture)"
msg_ok "Setup Docker Repository"

msg_info "Installing Docker"
$STD apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
msg_ok "Installed Docker"

mkdir -p /opt/arcane
cd /opt/arcane
curl -fsSL "https://raw.githubusercontent.com/getarcaneapp/arcane/refs/heads/main/docker/examples/compose.basic.yaml" -o "/opt/arcane/compose.yaml"

msg_info "Setup Arcane Environment"
curl -fsSL "https://raw.githubusercontent.com/getarcaneapp/arcane/refs/heads/main/.env.example" -o "/opt/arcane/.env"
APP_URL="http://localhost:3552"
ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d '/+=')
JWT_SECRET=$(openssl rand -base64 24 | tr -d '/+=')
STACK_DIR="/etc/arcane/stacks"

# sed -i '/ENCRYPTION_KEY=/ s|\(ENCRYPTION_KEY=\).*|\1'"$ENCRYPTION_KEY"'|' /opt/arcane/compose.yaml
# sed -i '/JWT_SECRET=/ s|\(JWT_SECRET=\).*|\1'"$JWT_SECRET"'|' /opt/arcane/compose.yaml
# sed -i "s/^APP_URL=.*/APP_URL=${APP_URL}/" /opt/arcane/.env
# sed -i "/^ENCRYPTION_KEY/ { /^[^#]/ s/^/#/ }" /opt/arcane/.env
# sed -i "/^JWT_SECRET/ { /^[^#]/ s/^/#/ }" /opt/arcane/.env
# sed -i "\|/host/path/to/projects:/app/data/projects| s|^\([[:space:]]*\).*|\1$STACK_DIR|" /opt/arcane/compose.yaml

sed -i '/^[[:space:]]*#/!s|/host/path/to/projects|'"$STACK_DIR"'|g' /opt/arcane/compose.yaml
sed -i '/^[[:space:]]*#/!s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY='"$ENCRYPTION_KEY"'|g' /opt/arcane/compose.yaml
sed -i '/^[[:space:]]*#/!s|JWT_SECRET=.*|JWT_SECRET='"$JWT_SECRET"'|g' /opt/arcane/compose.yaml
sed -i '/^[[:space:]]*#/!s|APP_URL=.*|APP_URL='"$APP_URL"'|g' /opt/arcane/.env
sed -i '/^[[:space:]]*#/!s|ENCRYPTION_KEY=.*|#&|g' /opt/arcane/.env
sed -i '/^[[:space:]]*#/!s|JWT_SECRET=.*|#&|g' /opt/arcane/.env

msg_ok "Setup Arcane Environment"

msg_info "Initialize Arcane"
$STD docker compose -p arcane -f /opt/arcane/compose.yaml --env-file /opt/arcane/.env up -d
msg_ok "Initialized Arcane"

motd_ssh
customize
cleanup_lxc
