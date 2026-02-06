#!/bin/bash

# ==========================
# REQUIRED VARIABLES
# ==========================
DOMAIN=staging.covisionperformance.com
PUBLIC_IP=16.58.89.9
EMAIL=admin@$DOMAIN

if [[ -z "$DOMAIN" || -z "$PUBLIC_IP" || -z "$EMAIL" ]]; then
  echo "❌ DOMAIN, PUBLIC_IP, or EMAIL missing in env file"
  exit 1
fi

echo "🚀 Applying SSL for $DOMAIN (IP: $PUBLIC_IP)"

# ==========================
# FIND SERVER BLOCK
# ==========================
NGINX_CONF=$(grep -R "server_name.*$PUBLIC_IP" /etc/nginx/sites-available -l | head -n 1)

if [ -z "$NGINX_CONF" ]; then
  echo "❌ No server block found using IP $PUBLIC_IP"
  exit 1
fi

echo "✅ Found Nginx config: $NGINX_CONF"

# ==========================
# UPDATE SERVER_NAME
# ==========================
sed -i "s/server_name .*${PUBLIC_IP}.*/server_name ${DOMAIN};/" "$NGINX_CONF"

# ==========================
# TEST & RELOAD NGINX
# ==========================
nginx -t || exit 1
systemctl reload nginx

echo "🔄 Nginx updated: $PUBLIC_IP → $DOMAIN"

# ==========================
# INSTALL CERTBOT (IF NEEDED)
# ==========================
if ! command -v certbot &> /dev/null; then
  echo "📦 Installing Certbot..."
  apt update -y
  apt install -y certbot python3-certbot-nginx
fi

# ==========================
# APPLY SSL
# ==========================
certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  -m "$EMAIL" \
  --redirect

# ==========================
# AUTO RENEW
# ==========================
systemctl enable certbot.timer
systemctl start certbot.timer

certbot renew --dry-run

echo "✅ SSL successfully applied: https://$DOMAIN"
