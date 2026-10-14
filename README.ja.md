# hermes-agents-quickstart

[English Document](README.md)

ローカル環境で [Hermes Agent](https://github.com/NousResearch/hermes-agent) を Docker Compose を用いて安全・軽量・クリーンに実行・管理するための設定リポジトリです。

> [!NOTE]
> **個人の検証メモ・実験用リポジトリ**
> 本リポジトリは、Hermes Agent および関連ツール（SearXNG / Firecrawl）をローカル環境で動作検証するための個人用ノート・動作記録です。
> 個人の備忘録・再現用設定であり、IssueやPRへの対応は保証しておりません（現状有姿 / AS-IS）。

> [!TIP]
> **公式プリビルトイメージ & クリーンスタート構成**
> 公式の Docker イメージ（`nousresearch/hermes-agent:latest`）を自動利用するため、**ソースコードのクローンやローカルビルドは不要**です。リポジトリ取得後、数秒〜数十秒ですぐに起動できます。
> 必要に応じてソースコードからローカルビルドするための導線（`./manage.sh build`）も用意されています。

---

## 主な特徴とセキュリティ設計

1. **ホストOS非破壊（sudo不要・iptables等不使用）**
   - ホストOSの設定やルーティングを一切変更せず、一般ユーザー権限（dockerグループ）だけで全操作が完結します。
2. **ポート公開は WebUI（9119）のみ・ループバック限定**
   - WebUI のみ `127.0.0.1:9119:9119` でホストのループバックにバインド（LAN露出を完全遮断）。
   - SearXNG（8080）、Firecrawl（3002）、内部API（8642）は内部ブリッジネットワーク（`mi_hermes_internal`）のコンテナ間通信（`expose`）に完全隔離。
3. **コンテナ特権剥奪（最小権限の原則）**
   - 全サービスに `security_opt: [no-new-privileges:true]` を適用。
   - ネットワーク特権（`CAP_NET_RAW`, `CAP_NET_ADMIN`）や危険な特権を完全にドロップし、コンテナ内からの特権昇格や偽装パケット送出を防止。
4. **Hermes Agent 内蔵の SSRF（ローカルLAN保護）機能**
   - エージェントが実行するWeb検索・抽出ツールは、プライベートIP（`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`）宛てのリクエストを自動ブロック。
5. **Compose Profiles による柔軟な起動形態**
   - 目的やマシンスペックに合わせて、最小構成・検索対応・フル構成を自在に切り替え可能。
6. **リソース枯渇・ログ肥大化防止（VPS安定運用設計）**
   - 全コンテナにメモリ上限を設定（OOM によるホスト応答停止を防止）し、Docker ログローテーション（`max-size: 10m`, `max-file: 3`）によりディスク枯渇を自動防止。

---

## ディレクトリ構成

```text
hermes-agents-quickstart/
├── docker-compose.yml       # 基本コンテナ定義 (公式プリビルトイメージ利用)
├── docker-compose.build.yml # (開発用) ローカルビルド用オーバーレイ
├── .env.example             # 環境変数テンプレート（UID/GID, Basic認証, 内部DNS）
├── .gitignore               # Git 除外設定
├── manage.sh                # 統合管理スクリプト (Profiles / build 対応)
├── config.yaml.example      # Hermes Agent 設定テンプレート
├── data/                    # Hermes データディレクトリ（コンテナ側 /opt/data）
│   ├── .gitkeep             # ディレクトリ保持用（実行時データはGit除外）
│   └── (スキル、記憶、セッション、state.db は起動時にゼロから生成されます)
├── services/                # セルフホスト検索・抽出サービス
│   ├── searxng/             # SearXNG 設定 (Compose統合)
│   └── firecrawl/           # Firecrawl 設定 (内部ネットワーク連携)
└── workspace/               # 作業ディレクトリ（コンテナ側 /workspace）
```

---

## セットアップ手順（最短3ステップ）

### 1. リポジトリのクローン
サブモジュールの取得は不要です。通常通りクローンします。

```bash
git clone https://github.com/chottokun/hermes-agents-quickstart.git
cd hermes-agents-quickstart
```

### 2. 環境変数の設定
設定テンプレートをコピーし、必要に応じて設定を調整します。

```bash
cp .env.example .env
```
※ `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` および `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` にWebダッシュボード用の認証情報を設定できます。

### 3. 初回セットアップ (TUI)
公式イメージが自動ダウンロードされ、初期設定ウィザード（APIキー等の入力）が立ち上がります。

```bash
./manage.sh setup
```

---

## 目的別の起動オプション

用途やリソースに合わせて、以下のオプションから選択して起動できます。

> [!TIP]
> **ワンコマンド起動・再開 (`./manage.sh run`)**
> `./manage.sh run`（または `./manage.sh up`）を実行すると、**前回起動したオプション（構成）を自動で記憶して即座に再開**します（初回は推奨構成の `search up` が起動）。日常の起動・再開はこれだけで完結します。

### Option A: WebUI + SearXNG（【推奨】軽量・Web検索対応構成）
WebUIで対話・監視しつつ、SearXNGで安全にWeb検索を行える推奨バランス構成です。
```bash
./manage.sh search up
# または: docker compose --profile search up -d
```

### Option B: WebUI 単体（外部検索なし・最小フットプリント）
リソースを最小限に抑えたい場合。
```bash
./manage.sh gateway up
# または: docker compose up -d gateway
```

### Option C: 対話型 CLI (TUI)
WebUI を常駐させず、ターミナルで対話したい時だけ一時起動します。Web検索（SearXNG）連動にも対応しています。
```bash
# CLI 単体セッション（軽量・検索なし）
./manage.sh cli

# CLI + SearXNG（Web検索連動）
./manage.sh cli search
# または: ./manage.sh search cli
```

### Option D: 全部入り（Firecrawlを含む完全構成）
Web検索に加え、ローカルWeb抽出（スクレイピング・Markdown化）も含めた完全構成です。
```bash
./manage.sh full up
```

---

## 開発者向け: ソースコードからのローカルビルド

エージェントのソースコードを変更・カスタマイズしてビルドしたい場合の導線も用意されています。

```bash
./manage.sh build
```
* **動作内容**:
  1. サブモジュール `hermes-agent` が存在しない場合は自動で取得（`git submodule update --init --recursive`）します。
  2. `docker-compose.build.yml` を使ってローカルイメージ `hermes-agent:local` をビルドします。
  3. ビルド後、`.env` に `HERMES_IMAGE=hermes-agent:local` が自動反映され、即座にローカルビルド版に切り替わります。

---

## ユースケース: Discord 等のメッセージングボット常駐運用 (24/7 稼働)

Hermes Agent は、対話 TUI で設定を行ったあと、`gateway` をバックグラウンド起動することで、Discord や Telegram 等のメッセージングボットとして 24時間365日 常駐稼働させることができます。

### 常駐運用の流れ

1. **TUI でプラットフォーム連携を設定**
   ```bash
   ./manage.sh setup
   # または: ./manage.sh cli
   ```
   初期ウィザードまたは対話 CLI 内で、LLM プロバイダーの API キーに加えて **Discord Bot Token** や通知先チャンネル等の設定を入力します。設定内容はすべて `data/` 配下に自動保存・永続化されます。設定完了後は TUI セッションを終了（`Ctrl+C` や `exit`）して構いません。

2. **バックグラウンド常駐起動**
   ```bash
   # Web検索（SearXNG）連動で常駐（推奨）
   ./manage.sh search up
   # またはワンコマンド再開: ./manage.sh run
   ```
   `gateway` コンテナがバックグラウンド（`-d`）で立ち上がり、Discord に自動接続してメッセージの受信・応答を開始します（`restart: unless-stopped` により、ホストや VPS 再起動時も自動復帰します）。

3. **稼働ログの確認**
   ```bash
   # ボットの通信・応答ログをリアルタイム表示
   docker compose logs -f gateway

   # 稼働ステータス確認
   ./manage.sh status
   ```

4. **常駐の停止**
   ```bash
   ./manage.sh down
   ```

---

## 停止とステータス確認・更新

```bash
# 全コンテナの稼働状況を確認
./manage.sh status

# 起動中の全サービスを一括停止
./manage.sh down

# 公式イメージを最新版に更新 (pull)
./manage.sh update
```

---

## リモートアクセス（SSH トンネル）

Webダッシュボード（9119）は **ホストのループバック（127.0.0.1）にのみバインド** されています。同一LANや外部インターネットから直接閲覧することはできません。
外部PCから安全にアクセスする場合は、SSH トンネルを利用します。

```bash
# SSH トンネル経由でポート 9119 を転送
ssh -N -L 9119:localhost:9119 <ユーザー名>@<サーバーホスト>
```

接続後、クライアント側のブラウザで `http://localhost:9119` を開き、`.env` で設定した Basic 認証情報でログインします。

---

## 本番・VPS 運用のポイント

1. **初期パスワード・シークレットの変更**
   VPS 等に配置して `.env` を作成する際、以下を手元でランダムな文字列に変更しておくことを推奨します（万が一のアクセス制御ミス時にも安全です）。
   - `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`: WebUI の Basic 認証パスワード
   - `SEARXNG_SECRET`: SearXNG のセッション暗号化キー（`.env` に記述することで安全に上書き可能）

2. **full 構成（Firecrawl）利用時の `data/config.yaml` 切り替え**
   自動初期化される `data/config.yaml` は、推奨構成に合わせて `extract_backend: "none"`（SearXNG のみ）になっています。
   Firecrawl を含むフル構成（`./manage.sh full up`）で Web ページ本文抽出・Markdown 変換を行う場合は、`data/config.yaml` の `extract_backend` を `"firecrawl"` に変更してください。

---

## ライセンス

[MIT License](LICENSE)
