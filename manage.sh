#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# ヘルプメッセージ
show_help() {
    cat << 'HELP_EOF'
hermes-agents-quickstart 統合管理スクリプト

使用方法:
  ./manage.sh [サービス/プロファイル] [コマンド]

目的別起動 (Compose Profiles):
  search        【推奨・軽量】WebUI + SearXNG (Web検索対応)
  gateway       WebUI 最小構成 (メタ検索・Web抽出なし)
  full          全部入り完全構成 (WebUI + SearXNG + Firecrawl)
  all           full と同等 (全サービス一括起動)

対話・セットアップ:
  cli           対話型 CLI (TUI) セッションを起動
  setup         Hermes Agent の初期セットアップ (TUI)

ビルド・更新:
  build         (開発用) hermes-agent サブモジュールを取得してローカルビルド
  update        公式Dockerイメージを最新版に更新 (docker compose pull)

個別サービス管理 (後方互換):
  hermes        Hermes Agent 単体操作
  searxng       SearXNG 単体操作
  firecrawl     Firecrawl 単体操作

システム全体操作:
  down          稼働中の全サービスを一括停止
  status        コンテナの稼働状況を表示
  firewall      [on|off|status] オプトインのローカルLAN通信遮断ルール

コマンド例:
  ./manage.sh search up        WebUI + SearXNG を起動 (推奨)
  ./manage.sh search down      WebUI + SearXNG を停止
  ./manage.sh gateway up       WebUI のみ起動
  ./manage.sh full up          全機能 (Firecrawl含む) を起動
  ./manage.sh down             全サービスを一括停止
  ./manage.sh cli              ターミナルで対話型CLIを起動
  ./manage.sh build            ローカルでソースからビルド
  ./manage.sh update           公式イメージを最新に更新
  ./manage.sh firewall on      (任意) ホストiptablesでLANへのパケットを遮断
HELP_EOF
}

# ローカルビルド処理
handle_build() {
    echo "=== Hermes Agent ローカルビルド ==="
    if [ ! -f "$DIR/hermes-agent/Dockerfile" ]; then
        echo "サブモジュール hermes-agent が見つかりません。Git サブモジュールを取得します..."
        git submodule update --init --recursive
    fi
    echo "ローカルイメージ (hermes-agent:local) をビルドしています..."
    docker compose -f docker-compose.yml -f docker-compose.build.yml build "$@"
    echo "ビルドが完了しました！"
    echo ""
    echo "ローカルビルドイメージを使用するには、.env に以下を設定してください:"
    echo "  HERMES_IMAGE=hermes-agent:local"
    echo ""
    read -r -p ".env の HERMES_IMAGE を hermes-agent:local に設定しますか？ [Y/n]: " ans || ans="y"
    case "$ans" in
        [nN]*)
            echo "設定をスキップしました。"
            ;;
        *)
            if grep -q "^HERMES_IMAGE=" .env 2>/dev/null; then
                sed -i 's/^HERMES_IMAGE=.*/HERMES_IMAGE=hermes-agent:local/' .env
            else
                echo "HERMES_IMAGE=hermes-agent:local" >> .env
            fi
            echo ".env を更新しました: HERMES_IMAGE=hermes-agent:local"
            ;;
    esac
}

# ファイアウォール (iptables) 制御
handle_firewall() {
    local action="${1:-status}"
    local private_cidrs=("192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12")

    case "$action" in
        on)
            echo "ホストOS iptables の DOCKER-USER チェーンにローカルLAN遮断ルールを適用します..."
            for cidr in "${private_cidrs[@]}"; do
                if sudo iptables -C DOCKER-USER -i br-+ -d "$cidr" -j DROP 2>/dev/null; then
                    echo "  - 既に登録済み: $cidr"
                else
                    sudo iptables -I DOCKER-USER -i br-+ -d "$cidr" -j DROP
                    echo "  - 遮断ルール追加: $cidr"
                fi
            done
            echo "ローカルLANへのパケット遮断が有効になりました。"
            ;;
        off)
            echo "ホストOS iptables からローカルLAN遮断ルールを解除します..."
            for cidr in "${private_cidrs[@]}"; do
                while sudo iptables -C DOCKER-USER -i br-+ -d "$cidr" -j DROP 2>/dev/null; do
                    sudo iptables -D DOCKER-USER -i br-+ -d "$cidr" -j DROP
                    echo "  - 遮断ルール削除: $cidr"
                done
            done
            echo "ローカルLANへのパケット遮断が解除されました。"
            ;;
        status)
            echo "=== iptables DOCKER-USER チェーンのLAN遮断ルール ==="
            sudo iptables -L DOCKER-USER -v -n 2>/dev/null | grep -E "(192\.168\.|10\.|172\.16\.)" || echo "現在、ローカルLAN遮断ルールは適用されていません (無効)。"
            ;;
        *)
            echo "使用方法: ./manage.sh firewall [on|off|status]"
            exit 1
            ;;
    esac
}

TARGET="${1:-status}"
ACTION="${2:-status}"

case "$TARGET" in
    # --------------------------------------------------
    # 目的別起動オプション (Profiles)
    # --------------------------------------------------
    search)
        case "$ACTION" in
            up)
                echo "WebUI + SearXNG (推奨軽量構成) を起動しています..."
                docker compose --profile search up -d
                echo "起動完了: WebUI (http://127.0.0.1:9119) / SearXNG (内部DNS: searxng:8080)"
                ;;
            down)
                echo "WebUI + SearXNG を停止しています..."
                docker compose --profile search down
                ;;
            logs)
                docker compose --profile search logs -f
                ;;
            status)
                docker compose --profile search ps
                ;;
            *)
                echo "不明なコマンドです: $ACTION (up, down, logs, status)"
                exit 1
                ;;
        esac
        ;;

    gateway|hermes)
        case "$ACTION" in
            up)
                echo "Hermes Gateway (WebUI 最小構成) を起動しています..."
                docker compose up -d gateway
                echo "起動完了: WebUI (http://127.0.0.1:9119)"
                ;;
            down)
                echo "Hermes Gateway を停止しています..."
                docker compose stop gateway
                ;;
            logs)
                docker compose logs -f gateway
                ;;
            cli)
                docker compose run --rm cli
                ;;
            setup)
                docker compose run --rm cli setup
                ;;
            status)
                docker compose ps gateway
                ;;
            *)
                echo "不明なコマンドです: $ACTION (up, down, logs, cli, setup, status)"
                exit 1
                ;;
        esac
        ;;

    searxng)
        case "$ACTION" in
            up)
                echo "SearXNG を起動しています..."
                docker compose --profile search up -d searxng
                echo "SearXNG が内部ネットワークで起動しました (searxng:8080)。"
                ;;
            down)
                echo "SearXNG を停止しています..."
                docker compose stop searxng
                ;;
            logs)
                docker compose logs -f searxng
                ;;
            status)
                docker compose ps searxng
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

    full|all)
        case "$ACTION" in
            up)
                echo "=== 1. WebUI + SearXNG を起動 ==="
                docker compose --profile search up -d
                echo "=== 2. Firecrawl を起動 ==="
                "$DIR/services/firecrawl/run.sh" up
                echo "全サービスが内部ネットワーク上で起動しました。"
                echo "WebUI: http://127.0.0.1:9119"
                ;;
            down)
                echo "全サービスを停止しています..."
                "$DIR/services/firecrawl/run.sh" down || true
                docker compose --profile search down || true
                echo "全サービスが停止しました。"
                ;;
            status)
                docker compose --profile search ps
                "$DIR/services/firecrawl/run.sh" status || true
                ;;
            *)
                echo "不明なコマンドです: $ACTION (up, down, status)"
                exit 1
                ;;
        esac
        ;;

    # --------------------------------------------------
    # 対話 / セットアップ / ビルド / 更新
    # --------------------------------------------------
    cli)
        docker compose run --rm cli
        ;;

    setup)
        docker compose run --rm cli setup
        ;;

    build)
        handle_build "$@"
        ;;

    update|pull)
        echo "公式イメージを最新に更新しています..."
        docker compose pull
        echo "イメージの更新が完了しました。"
        ;;

    down)
        echo "稼働中の全サービスを停止しています..."
        if [ -d "$DIR/services/firecrawl/src" ]; then
            "$DIR/services/firecrawl/run.sh" down || true
        fi
        docker compose --profile search down || true
        docker compose down || true
        echo "停止が完了しました。"
        ;;

    status)
        echo "=== コンテナ稼働状況 ==="
        docker compose --profile search ps
        if [ -d "$DIR/services/firecrawl/src" ]; then
            echo ""
            echo "--- Firecrawl ---"
            "$DIR/services/firecrawl/run.sh" status || true
        fi
        ;;

    firewall)
        handle_firewall "$ACTION"
        ;;

    help|-h|--help)
        show_help
        ;;

    *)
        show_help
        exit 1
        ;;
esac
