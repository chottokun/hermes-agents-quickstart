#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$DIR/src"

if [ ! -d "$SRC_DIR" ]; then
    echo "Firecrawl is not set up yet. Running setup first..."
    "$DIR/setup.sh"
fi

cd "$SRC_DIR"

ACTION="${1:-up}"

case "$ACTION" in
    up)
        echo "Starting Firecrawl containers..."
        docker compose up -d
        echo "Firecrawl started on port 3002."
        ;;
    down)
        echo "Stopping Firecrawl containers..."
        docker compose down
        ;;
    logs)
        docker compose logs -f
        ;;
    status)
        docker compose ps
        ;;
    *)
        echo "Usage: $0 [up|down|logs|status]"
        exit 1
        ;;
esac
