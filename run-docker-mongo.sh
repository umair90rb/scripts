#!/bin/bash
set -e

####################################
# CONFIG
####################################
MONGO_USER="admin"
MONGO_PASS="StrongPassword123"
REPLSET_NAME="rs0"
CONTAINER_NAME="mongodb"
DATA_VOLUME="mongo_data"
KEY_DIR="/home/ubuntu/mongo-key"
KEY_FILE="$KEY_DIR/mongodb.key"
MONGO_PORT=27017

####################################
# Replica IP Mode
####################################

USE_PUBLIC_IP_FOR_REPLICA=true   # change to false if app+db on same EC2

PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

if [ "$USE_PUBLIC_IP_FOR_REPLICA" = false ]; then
  REPLICA_HOST="localhost"
  echo "Replica will use localhost"
else
  REPLICA_HOST="$PUBLIC_IP"
  echo "Replica will use public IP: $REPLICA_HOST"
fi


echo "Using Public IP: $PUBLIC_IP"

####################################
# Install Docker (if missing)
####################################
if command -v docker &> /dev/null; then
  echo "Docker already installed."
else
  echo "Installing Docker..."
  sudo apt update -y
  sudo apt install -y docker.io
fi

# Ensure Docker service running
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
if groups ubuntu | grep -q docker; then
  echo "User already in docker group."
else
  sudo usermod -aG docker ubuntu
  echo "Added ubuntu user to docker group."
  echo "⚠️ Logout & login again for docker group to take effect."
fi

# =============================
# Ensure MongoDB volume exists
# =============================
if ! docker volume inspect $DATA_VOLUME >/dev/null 2>&1; then
  echo "📁 Creating MongoDB volume..."
  docker volume create $DATA_VOLUME >/dev/null 2>&1 || true
fi

####################################
# Create Keyfile
####################################
echo "Creating MongoDB keyfile..."
sudo rm -rf $KEY_DIR
sudo mkdir -p $KEY_DIR
openssl rand -base64 756 | sudo tee $KEY_FILE >/dev/null
sudo chmod 400 $KEY_FILE
sudo chown root:root $KEY_FILE

####################################
# Remove Old Container
####################################
docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true

####################################
# Run MongoDB
####################################
echo "Starting MongoDB container..."

docker run -d \
  --name $CONTAINER_NAME \
  --restart unless-stopped \
  -p $MONGO_PORT:27017 \
  -v $DATA_VOLUME:/data/db \
  -v $KEY_FILE:/etc/mongodb-keyfile:ro \
  -e MONGO_INITDB_ROOT_USERNAME=$MONGO_USER \
  -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASS \
  mongo:7.0 \
  --replSet $REPLSET_NAME \
  --keyFile /etc/mongo-key/mongodb.key \
  --bind_ip_all

####################################
# Wait for MongoDB
####################################
echo "Waiting for MongoDB to start..."
sleep 15

####################################
# Initialize Replica Set
####################################
echo "Initializing replica set..."

docker exec $CONTAINER_NAME mongosh -u $MONGO_USER -p $MONGO_PASS --authenticationDatabase admin <<EOF
rs.initiate({
  _id: "$REPLSET_NAME",
  members: [{ _id: 0, host: "$PUBLIC_IP:27017" }]
})
EOF

sleep 5

####################################
# Verify
####################################
docker exec $CONTAINER_NAME mongosh -u $MONGO_USER -p $MONGO_PASS --authenticationDatabase admin <<EOF
rs.status()
EOF

echo ""
echo "======================================"
echo "MongoDB Replica Set Ready!"
echo ""
echo "Connection String:"
echo "mongodb://$MONGO_USER:$MONGO_PASS@$PUBLIC_IP:27017/covision?authSource=admin&replicaSet=$REPLSET_NAME"
echo "======================================"
