# hermes-agents-quickstart

[English Document](README.md)

ローカル環境で [Hermes Agent](https://github.com/NousResearch/hermes-agent) を Docker Compose を用いて実行・管理するための設定リポジトリです。

> [!NOTE]
> **個人の検証メモ・実験用リポジトリ**
> 本リポジトリは、Hermes Agent および関連ツール（SearXNG / Firecrawl）をローカル環境で動作検証するための個人用ノート・動作記録です。
> 個人の備忘録・再現用設定であり、IssueやPRへの対応は保証しておりません（現状有姿 / AS-IS）。

> [!TIP]
> **クリーンスタート構成**
> 本リポジトリには設定テンプレートとオーケストレーション用のスクリプトのみを含めています。エージェントが生成した成果物（カスタムスキル、記憶、会話セッション、データベース等）は一切含んでいないため、ゼロからクリーンにセットアップできます。

## 概要

設定ファイル、サービス連携スクリプト、作業ディレクトリをホスト側に配置しつつ、認証情報（APIキー）、セッション履歴、データベースなどの成果物全般を Git 管理対象から除外できるように構成しています。

## ディレクトリ構成

```text
hermes-agents-quickstart/
├── hermes-agent/       # Hermes Agent リポジトリ（Git サブモジュール）
├── docker-compose.yml  # コンテナ定義
├── .env.example        # 環境変数テンプレート（UID/GID）
├── .gitignore          # Git 除外設定
├── manage.sh           # サービス管理スクリプト
├── config.yaml.example # Hermes Agent 設定テンプレート
├── data/               # Hermes データディレクトリ（コンテナ側 /opt/data）
│   ├── .gitkeep        # ディレクトリ保持用（実行時データはGit除外）
│   └── (スキル、記憶、セッション、state.db は起動時にゼロから生成されます)
├── services/           # セルフホスト検索・抽出サービス
│   ├── searxng/        # SearXNG 設定
│   └── firecrawl/      # Firecrawl 設定
└── workspace/          # 作業ディレクトリ（コンテナ側 /workspace）
```

## セットアップ手順

### 1. サブモジュールの取得
リポジトリをクローン後、サブモジュールを初期化します。

```bash
git submodule update --init --recursive
```

### 2. 環境変数の設定
ホストユーザーの UID/GID を設定します（通常は 1000）。

```bash
cp .env.example .env
```

### 3. イメージのビルド
```bash
docker compose build
```

### 4. 初回セットアップ
API キーやモデルプロバイダーの設定を行います（設定は `data/.env` に保存されます）。

```bash
docker compose run --rm cli setup
```

## 起動方法

### CLI（対話型チャット）
```bash
docker compose run --rm cli
```

### Gateway / Web ダッシュボード（バックグラウンド起動）
```bash
docker compose up -d
```

- Web ダッシュボード: `http://127.0.0.1:9119`
- ログ確認: `docker compose logs -f`
- 停止: `docker compose down`

## セルフホスト検索・抽出エンジン (SearXNG / Firecrawl)

Web 検索およびページ抽出用のローカルサービスです。

| サービス | 役割 | ポート | 起動コマンド |
| :--- | :--- | :--- | :--- |
| **SearXNG** | キーワード検索 (`web_search`) | `8888` | `./manage.sh searxng up` |
| **Firecrawl** | Web ページ抽出・Markdown 変換 (`web_extract`) | `3002` | `./manage.sh firecrawl up` |

### Hermes Agent への設定反映
1. **環境変数の設定** (`data/.env` または `.env`):
   ```bash
   SEARXNG_URL=http://localhost:8888
   FIRECRAWL_API_URL=http://localhost:3002
   FIRECRAWL_API_KEY=fc-local-key
   ```
2. **バックエンドの指定** (`data/config.yaml`):
   `config.yaml.example` を参考に以下を設定します。
   ```yaml
   web:
     search_backend: "searxng"
     extract_backend: "firecrawl"
   ```

## 統合管理スクリプト (`./manage.sh`)

各種サービスの起動・停止を行います。

```bash
# 稼働状況の確認
./manage.sh status

# SearXNG の起動・停止
./manage.sh searxng up
./manage.sh searxng down

# Firecrawl の起動・停止（初回は自動セットアップ）
./manage.sh firecrawl up
./manage.sh firecrawl down

# 全サービス（SearXNG + Firecrawl + Hermes）の一括起動・停止
./manage.sh all up
./manage.sh all down
```

## リモートアクセス（SSH トンネル）

ダッシュボード（ポート 9119）はローカルホスト（127.0.0.1）にバインドされています。外部マシンからアクセスする場合は SSH トンネルを利用します。

```bash
# ダッシュボード（9119）を転送
ssh -N -L 9119:localhost:9119 <ユーザー名>@<サーバーホスト>

# ダッシュボード（9119）および API サーバー（8642）を転送
ssh -N -L 9119:localhost:9119 -L 8642:localhost:8642 <ユーザー名>@<サーバーホスト>
```

接続後、クライアント側のブラウザで `http://localhost:9119` を開きます。

## Git 管理方針

- **管理対象**:
  - `docker-compose.yml`, `.env.example`, `config.yaml.example`, `.gitignore`, `README.md`, `README.ja.md`, `manage.sh`
  - ディレクトリ保持プレースホルダー (`data/.gitkeep`, `workspace/.gitkeep`)
- **除外対象**:
  - `.env`, `data/.env`（APIキー等）
  - `data/*`（スキル、セッション、記憶、内部データベース等）
  - `workspace/*`（作業ファイル・ダウンロード物）

## ライセンス

[MIT License](LICENSE)
