#!/bin/bash
set -e

echo "🚀 Deploying MongoDB & Redis (single-file script)..."

# =============================
# CONFIGURATION (EDIT HERE)
# =============================

# MongoDB
MONGO_CONTAINER="mongodb"
MONGO_IMAGE="mongo:7"
MONGO_VOLUME="mongo_data"
MONGO_ROOT_USERNAME="admin"
MONGO_ROOT_PASSWORD="SuperSecurePassword@2026!"
MONGO_DB_NAME="appdb"

# Redis
REDIS_CONTAINER="redis"
REDIS_IMAGE="redis:7"
REDIS_PASSWORD="SuperSecurePassword@2026!"

# =============================
# Pull latest images
# =============================
echo "📦 Pulling Docker images..."
docker pull $MONGO_IMAGE
docker pull $REDIS_IMAGE

# =============================
# Stop & remove old containers
# =============================
echo "🛑 Stopping existing containers..."
for c in $MONGO_CONTAINER $REDIS_CONTAINER; do
  if docker ps -q -f name=^${c}$ >/dev/null; then
    docker stop $c
  fi
done

echo "🗑 Removing old containers (volumes preserved)..."
for c in $MONGO_CONTAINER $REDIS_CONTAINER; do
  if docker ps -aq -f name=^${c}$ >/dev/null; then
    docker rm $c | true
  fi
done

# =============================
# Ensure MongoDB volume exists
# =============================
if ! docker volume inspect $MONGO_VOLUME >/dev/null 2>&1; then
  echo "📁 Creating MongoDB volume..."
  docker volume create $MONGO_VOLUME
fi

# =============================
# Run MongoDB
# =============================
echo "🍃 Starting MongoDB container..."
docker run -d \
  --name $MONGO_CONTAINER \
  --restart unless-stopped \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=$MONGO_ROOT_USERNAME \
  -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_ROOT_PASSWORD \
  -e MONGO_INITDB_DATABASE=$MONGO_DB_NAME \
  -v $MONGO_VOLUME:/data/db \
  $MONGO_IMAGE

# =============================
# Run Redis
# =============================
echo "🔴 Starting Redis container..."
docker run -d \
  --name $REDIS_CONTAINER \
  --restart unless-stopped \
  -p 6379:6379 \
  $REDIS_IMAGE \
  redis-server --requirepass $REDIS_PASSWORD

# =============================
# Status check
# =============================
echo "🧪 Running containers:"
docker ps | grep -E "mongodb|redis"

echo ""
echo "✅ Deployment completed successfully!"
