#!/bin/bash
# Copy backend-requirements to backend server.
# Usage: ./deploy-backend-requirements.sh
# You will be prompted for root@172.240.241.179 password.

set -e
SERVER="root@172.240.241.179"
REMOTE_DIR="/var/www/html/tajiri/docs"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)/backend-requirements"

echo "Creating $REMOTE_DIR on server if needed..."
ssh "$SERVER" "mkdir -p $REMOTE_DIR"

echo "Copying backend-requirements to $SERVER:$REMOTE_DIR/ ..."
scp -r "$LOCAL_DIR" "$SERVER:$REMOTE_DIR/"

echo "Done. Contents at $SERVER:$REMOTE_DIR/backend-requirements/"
