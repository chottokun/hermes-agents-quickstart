#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$DIR/src"

echo "=== Firecrawl Setup ==="

if [ ! -d "$SRC_DIR" ]; then
    echo "Cloning official Firecrawl repository..."
    git clone https://github.com/mendableai/firecrawl.git "$SRC_DIR"
else
    echo "Firecrawl repository already exists in $SRC_DIR"
fi

cd "$SRC_DIR"

if [ ! -f .env ]; then
    echo "Creating .env configuration..."
    if [ -f apps/api/.env.example ]; then
        cp apps/api/.env.example .env
    else
        touch .env
    fi
    # ローカル用設定を追加
    cat << 'ENV_EOF' >> .env

# Hermes Agent Local Integration Settings
USE_DB_AUTHENTICATION=false
TEST_API_KEY=fc-local-key
PORT=3002
ENV_EOF
fi

echo "Setup complete. You can start Firecrawl with: ./services/firecrawl/run.sh up"
