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
mkdir -p /opt/monitoring-stack

echo "Copying configuration files..."
mv alertmanager/ /opt/monitoring-stack/
mv blackbox/ /opt/monitoring-stack/
mv grafana/ /opt/monitoring-stack/
mv nginx/ /opt/monitoring-stack/
mv portainer-data/ /opt/monitoring-stack/
mv prometheus/ /opt/monitoring-stack/
mv docker-compose.yml /opt/monitoring-stack/

echo "🔧 Setting permissions for persistent data..."
# Prometheus runs as UID 65534 (nobody)
sudo chmod -R 777 /opt/monitoring-stack
sudo chown -R 65534:65534 /opt/monitoring-stack/prometheus/data
# Grafana runs as UID 472
sudo chown -R 472:472 /opt/monitoring-stack/grafana/data
echo "✅ Monitoring directories moved and permissions set."


echo "Launching services with Docker Compose..."
cd /opt/monitoring-stack
docker compose up -d

echo "Monitoring stack deployment complete."