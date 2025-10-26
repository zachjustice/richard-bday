#!/bin/bash

# Digital Ocean Ubuntu 22.04 Server Setup Script for Kamal Deployment
# Run this script on your Digital Ocean droplet before deploying

set -e

echo "🚀 Setting up Digital Ocean server for Kamal deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add current user to docker group
echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

# Install Docker Compose (Kamal dependency)
echo "🔧 Installing Docker Compose..."
sudo apt-get install -y docker-compose-plugin

# Create storage directory for SQLite databases
echo "💾 Creating storage directory..."
sudo mkdir -p /var/lib/richard-bday-storage
sudo chown $USER:$USER /var/lib/richard-bday-storage

# Install GitHub CLI
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# Configure firewall (optional - uncomment if needed)
# echo "🔥 Configuring firewall..."
# sudo ufw allow ssh
# sudo ufw allow 80
# sudo ufw allow 443
# sudo ufw --force enable
sudo ufw limit ssh


# If small server, setup https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04#adjusting-the-cache-pressure-setting

echo "✅ Server setup complete!"
echo ""
echo "Next steps:"
echo "1. Log out and log back in for docker group changes to take effect"
echo "2. Push to main branch to trigger deployment"
echo ""
echo "To test Docker installation:"
echo "  docker --version"
echo "  docker compose version"
