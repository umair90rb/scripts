#!/bin/bash

# ==========================
# CONFIGURATION
# ==========================
DOMAIN="staging.covisionperformance.com"
EMAIL="admin@$DOMAIN"

# ==========================
# CHECK ROOT
# ==========================
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

echo "🚀 Starting SSL setup for $DOMAIN"

# ==========================
# UPDATE SERVER
# ==========================
echo "📦 Updating packages..."
apt update -y

# ==========================
# INSTALL NGINX
# ==========================
echo "🌐 Installing Nginx..."
apt install nginx -y
systemctl enable nginx
systemctl start nginx

# ==========================
# ALLOW FIREWALL
# ==========================
if command -v ufw &> /dev/null; then
  echo "🔥 Configuring UFW..."
  ufw allow OpenSSH
  ufw allow 'Nginx Full'
  ufw --force enable
fi

# ==========================
# INSTALL CERTBOT
# ==========================
echo "🔐 Installing Certbot..."
apt install certbot python3-certbot-nginx -y

# ==========================
# OBTAIN SSL
# ==========================
echo "🔑 Requesting SSL certificate..."
certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  -m "$EMAIL" \
  --redirect

# ==========================
# AUTO RENEW
# ==========================
echo "♻️ Setting up auto-renew..."
systemctl enable certbot.timer
systemctl start certbot.timer

# ==========================
# TEST RENEWAL
# ==========================
echo "🧪 Testing renewal..."
certbot renew --dry-run

# ==========================
# DONE
# ==========================
echo "✅ SSL successfully installed for https://$DOMAIN"
