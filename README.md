# mi-harmes

Hermes Agent を Docker Compose で実行・管理するための設定リポジトリです。

設定、スキル、作業成果物をホスト側のディレクトリに保存し、認証情報やログを除外して Git で管理できるように構成しています。

## ディレクトリ構成

```text
mi-harmes/
├── hermes-agent/       # Hermes Agent リポジトリ（Git サブモジュール）
├── docker-compose.yml  # コンテナ定義
├── .env.example        # 環境変数テンプレート（UID/GID）
├── .gitignore          # Git 除外設定
├── data/               # Hermes データディレクトリ（コンテナ側 /opt/data）
│   ├── skills/         # スキル（Git 管理対象）
│   ├── memories/       # 記憶データ（Git 除外）
│   ├── sessions/       # セッション履歴（Git 除外）
│   ├── state.db        # 内部データベース（Git 除外）
│   └── .env            # APIキー・認証情報（Git 除外）
└── workspace/          # 作業ディレクトリ（コンテナ側 /workspace）
                        # 実行時に生成されるコードやダウンロードファイル
```

## セットアップ

### 1. サブモジュールの取得
リポジトリをクローンした環境でサブモジュールを初期化します。

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
API キーやプロバイダーの設定を行います（設定は `data/.env` に保存されます）。

```bash
docker compose run --rm cli setup
```

## 起動方法

### CLI（対話型チャット）
```bash
docker compose run --rm cli
```

### Gateway / ダッシュボード（バックグラウンド起動）
```bash
docker compose up -d
```

- ダッシュボード: `http://127.0.0.1:9119`
- ログ確認: `docker compose logs -f`
- 停止: `docker compose down`

## セルフホスト検索・抽出エンジン (SearXNG / Firecrawl)

外部 API 費用をかけずに Web 検索・ページ抽出を行うためのセルフホストサービスです。

| サービス | 役割 | ポート | 起動方法 |
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

全サービスの起動・停止・確認をワンコマンドで行えます。

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

## リモートアクセス（トンネル経由）

ダッシュボード（ポート 9119）はローカルホスト（127.0.0.1）にバインドされているため、他のマシンからアクセスする場合は SSH トンネル（暗号化トンネル）を利用します。

接続元（クライアント PC 等）の端末で以下を実行します：

```bash
# ダッシュボード（9119）をローカルに転送
ssh -N -L 9119:localhost:9119 <ユーザー名>@<サーバーIPまたはホスト名>
```

※ API サーバー（8642）も同時に転送する場合：
```bash
ssh -N -L 9119:localhost:9119 -L 8642:localhost:8642 <ユーザー名>@<サーバーIPまたはホスト名>
```

トンネル接続後、クライアント側のブラウザで `http://localhost:9119` を開いてアクセスします。

## Git 管理方針

- **管理対象**:
  - `docker-compose.yml`, `.env.example`, `.gitignore`, `README.md`
  - `data/skills/`（保存されたスキル定義）
- **除外対象（.gitignore）**:
  - `data/.env`（APIキー等）
  - `data/sessions/`, `data/memories/`, `data/state.db*`（セッション・記憶・DB）
  - `workspace/*`（作業ファイル・ダウンロードファイル）
