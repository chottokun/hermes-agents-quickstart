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
        # 内部ネットワークが存在しない場合は作成
        if ! docker network inspect mi_hermes_internal >/dev/null 2>&1; then
            echo "内部ネットワーク mi_hermes_internal を作成しています..."
            docker network create mi_hermes_internal
        fi
        echo "Firecrawl コンテナ群を起動しています..."
        docker compose up -d
        echo "Firecrawl が内部ネットワーク上で起動しました（http://firecrawl:3002）。"
        ;;
    down)
        echo "Firecrawl コンテナ群を停止しています..."
        docker compose down
        ;;
    logs)
        docker compose logs -f
        ;;
    status)
        docker compose ps
        ;;
    *)
        echo "使用方法: $0 [up|down|logs|status]"
        exit 1
        ;;
esac
