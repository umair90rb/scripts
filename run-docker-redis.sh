#!/bin/bash
set -e

echo "🚀 Deploying Redis (single-file script)..."

# =============================
# CONFIGURATION (EDIT HERE)
# =============================

# Redis
REDIS_CONTAINER="redis"
REDIS_IMAGE="redis:7"
REDIS_NETWORK="my_network"

# =============================
# Pull latest images
# =============================
echo "📦 Pulling Docker images..."
docker pull $REDIS_IMAGE

# =============================
# Stop & remove old containers
# =============================
echo "🛑 Stopping existing containers..."
for c in $REDIS_CONTAINER; do
  if docker ps -q -f name=^${c}$ >/dev/null; then
    docker stop $c 2>/dev/null || true
  fi
done

echo "🗑 Removing old containers (volumes preserved)..."
for c in $REDIS_CONTAINER; do
  if docker ps -aq -f name=^${c}$ >/dev/null; then
    docker rm $c 2>/dev/null || true
  fi
done

# =============================
# Run Redis
# =============================
echo "🔴 Starting Redis container..."
docker run -d \
  --name $REDIS_CONTAINER \
  --restart unless-stopped \
  -p 6379:6379 \
  -n $REDIS_NETWORK \
  $REDIS_IMAGE \
  redis-server \

# =============================
# Status check
# =============================
echo "🧪 Running containers:"
docker ps | grep -E "redis"

echo ""
echo "✅ Deployment completed successfully!"
