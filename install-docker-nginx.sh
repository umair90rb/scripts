#!/bin/bash
set -e

echo "🚀 Starting server setup..."

# -------------------------
# Update system
# -------------------------
echo "📦 Updating system..."
sudo apt update -y
sudo apt upgrade -y

# -------------------------
# Install basic utilities
# -------------------------
echo "🔧 Installing basic tools..."
sudo apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common

# -------------------------
# Install Docker
# -------------------------
echo "🐳 Installing Docker..."

# Remove old versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
sudo usermod -aG docker $USER

echo "✅ Docker installed"

# -------------------------
# Install Nginx
# -------------------------
echo "🌐 Installing Nginx..."
sudo apt install -y nginx

sudo systemctl enable nginx
sudo systemctl start nginx

# -------------------------
# Firewall (UFW)
# -------------------------
echo "🔥 Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# -------------------------
# Create common directories
# -------------------------
echo "📁 Creating app directories..."
sudo mkdir -p /var/www
sudo chown -R $USER:$USER /var/www

# -------------------------
# Final checks
# -------------------------
echo "🧪 Checking versions..."
docker --version
docker compose version
nginx -v

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "⚠️ IMPORTANT:"
echo "👉 Logout and login again to use Docker without sudo"
