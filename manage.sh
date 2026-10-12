#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
hermes-agents-quickstart 統合管理スクリプト

使用方法:
  ./manage.sh [サービス] [コマンド]

サービス:
  hermes       Hermes Agent (メインエージェント)
  searxng      SearXNG (セルフホスト検索エンジン: ポート 8888)
  firecrawl    Firecrawl (セルフホストWeb抽出エンジン: ポート 3002)
  all          全サービス一括操作
  status       全コンテナの稼働状況を表示

コマンド例:
  ./manage.sh hermes up        Hermes Agent (Gateway/Dashboard) を起動
  ./manage.sh hermes down      Hermes Agent を停止
  ./manage.sh hermes cli       Hermes Agent の対話型CLIを起動
  ./manage.sh hermes logs      Hermes Agent のログを表示

  ./manage.sh searxng up       SearXNG を起動
  ./manage.sh searxng down     SearXNG を停止
  ./manage.sh searxng logs     SearXNG のログを表示

  ./manage.sh firecrawl up     Firecrawl を起動 (初回は自動セットアップ)
  ./manage.sh firecrawl down   Firecrawl を停止
  ./manage.sh firecrawl logs   Firecrawl のログを表示

  ./manage.sh all up           SearXNG + Firecrawl + Hermes をすべて起動
  ./manage.sh all down         全サービスを停止
  ./manage.sh status           現在の稼働状態を確認
EOF
}

TARGET="${1:-status}"
ACTION="${2:-status}"

case "$TARGET" in
    hermes)
        case "$ACTION" in
            up)
                echo "Hermes Agent を起動しています..."
                docker compose up -d
                ;;
            down)
                echo "Hermes Agent を停止しています..."
                docker compose down
                ;;
            logs)
                docker compose logs -f
                ;;
            cli)
                docker compose run --rm cli
                ;;
            setup)
                docker compose run --rm cli setup
                ;;
            status)
                docker compose ps
                ;;
            *)
                echo "不明なコマンドです: $ACTION (up, down, logs, cli, setup, status)"
                exit 1
                ;;
        esac
        ;;

    searxng)
        cd "$DIR/services/searxng"
        case "$ACTION" in
            up)
                echo "SearXNG を起動しています..."
                docker compose up -d
                echo "SearXNG がポート 8888 で起動しました。"
                ;;
            down)
                echo "SearXNG を停止しています..."
                docker compose down
                ;;
            logs)
                docker compose logs -f
                ;;
            status)
                docker compose ps
                ;;
            *)
                echo "不明なコマンドです: $ACTION (up, down, logs, status)"
                exit 1
                ;;
        esac
        ;;

    firecrawl)
        case "$ACTION" in
            setup)
                "$DIR/services/firecrawl/setup.sh"
                ;;
            up|down|logs|status)
                "$DIR/services/firecrawl/run.sh" "$ACTION"
                ;;
            *)
                echo "不明なコマンドです: $ACTION (setup, up, down, logs, status)"
                exit 1
                ;;
        esac
        ;;

    all)
        case "$ACTION" in
            up)
                echo "=== 1. SearXNG を起動 ==="
                (cd "$DIR/services/searxng" && docker compose up -d)
                
                echo "=== 2. Firecrawl を起動 ==="
                "$DIR/services/firecrawl/run.sh" up
                
                echo "=== 3. Hermes Agent を起動 ==="
                (cd "$DIR" && docker compose up -d)
                
                echo "全サービスが起動しました。"
                ;;
            down)
                echo "全サービスを停止しています..."
                (cd "$DIR" && docker compose down) || true
                "$DIR/services/firecrawl/run.sh" down || true
                (cd "$DIR/services/searxng" && docker compose down) || true
                echo "全サービスが停止しました。"
                ;;
            *)
                echo "不明なコマンドです: $ACTION (up, down)"
                exit 1
                ;;
        esac
        ;;

    status)
        echo "=== コンテナ稼働状況 ==="
        echo "--- Hermes Agent ---"
        (cd "$DIR" && docker compose ps) || true
        echo ""
        echo "--- SearXNG ---"
        (cd "$DIR/services/searxng" && docker compose ps) || true
        echo ""
        echo "--- Firecrawl ---"
        if [ -d "$DIR/services/firecrawl/src" ]; then
            (cd "$DIR/services/firecrawl/src" && docker compose ps) || true
        else
            echo "未セットアップ (./manage.sh firecrawl up で自動導入)"
        fi
        ;;

    help|-h|--help)
        show_help
        ;;

    *)
        show_help
        exit 1
        ;;
esac
