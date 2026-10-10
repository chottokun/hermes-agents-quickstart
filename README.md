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

## Git 管理方針

- **管理対象**:
  - `docker-compose.yml`, `.env.example`, `.gitignore`, `README.md`
  - `data/skills/`（保存されたスキル定義）
- **除外対象（.gitignore）**:
  - `data/.env`（APIキー等）
  - `data/sessions/`, `data/memories/`, `data/state.db*`（セッション・記憶・DB）
  - `workspace/*`（作業ファイル・ダウンロードファイル）
