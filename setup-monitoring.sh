#!/bin/bash

set -euo pipefail

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo." >&2
  exit 1
fi

# Full setup for Ubuntu: Docker, Docker Compose (plugin + classic), monitoring project folder

set -e

echo "🔄 Updating system..."
sudo apt update

echo "🐳 Installing Docker Engine and Compose plugin..."
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and plugin-based Compose
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding user to docker group (if not root) and enabling Docker..."
if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
  user="${SUDO_USER}"
else
  user="$(whoami)"
fi
if [ "$user" != "root" ]; then
  usermod -aG docker "$user"
fi
systemctl enable docker
systemctl start docker

# Optional: install classic `docker-compose` binary (for backward compatibility)
echo "⬇️ Installing classic docker-compose binary..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


echo "📁 Creating monitoring project folder structure..."
mkdir -p /opt/monitoring-stack/{prometheus/{data,file_sd},alertmanager,grafana/data,blackbox,portainer-data,nginx/{conf.d,certs,logs}}

echo "🔧 Setting permissions for persistent data..."
# Prometheus runs as UID 65534 (nobody)
sudo chmod -R 777 /opt/monitoring-stack
sudo chown -R 65534:65534 /opt/monitoring-stack/prometheus/data
# Grafana runs as UID 472
sudo chown -R 472:472 /opt/monitoring-stack/grafana/data
echo "✅ Monitoring directories created and permissions set."

# Determine the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Copying configuration files from $SCRIPT_DIR..."
# Declare an associative array mapping source files to target directories
declare -A file_map=(
  ["docker-compose.yml"]="/opt/monitoring-stack/"
  ["prometheus.yml"]="/opt/monitoring-stack/prometheus/"
  ["alert.rules.yml"]="/opt/monitoring-stack/prometheus/"
  ["alertmanager.yml"]="/opt/monitoring-stack/alertmanager/"
  ["config.yml"]="/opt/monitoring-stack/blackbox/"
  ["nginx-grafana.conf"]="/opt/monitoring-stack/nginx/conf.d/"
  ["nginx-prometheus.conf"]="/opt/monitoring-stack/nginx/conf.d/"
  ["nginx-portainer.conf"]="/opt/monitoring-stack/nginx/conf.d/"
  ["nginx-alertmanager.conf"]="/opt/monitoring-stack/nginx/conf.d/"
  ["nginx_access.log"]="/opt/monitoring-stack/nginx/logs/"
  ["nginx_error.log"]="/opt/monitoring-stack/nginx/logs/"
  ["snmp_targets.yml"]="/opt/monitoring-stack/prometheus/file_sd/"
  ["win_targets.yml"]="/opt/monitoring-stack/prometheus/file_sd/"
  ["node_targets.yml"]="/opt/monitoring-stack/prometheus/file_sd/"
  ["ping_targets.yml"]="/opt/monitoring-stack/prometheus/file_sd/"
  ["blackbox_targets.yml"]="/opt/monitoring-stack/prometheus/file_sd/"
)

# Iterate through the array and copy each file if it exists
for file in "${!file_map[@]}"; do
  src="$SCRIPT_DIR/$file"
  dest="${file_map[$file]}"
  
  if [ -f "$src" ]; then
    cp "$src" "$dest"
    echo "Copied $file to $dest"
  else
    echo "Warning: $file not found in $SCRIPT_DIR"
  fi
done

echo "Launching services with Docker Compose..."
cd /opt/monitoring-stack
docker compose up -d

echo "Monitoring stack deployment complete."