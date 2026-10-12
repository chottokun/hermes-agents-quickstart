# mi-harmes

[日本語ドキュメント (Japanese)](README.ja.md)

Docker Compose configuration for running and managing [Hermes Agent](https://github.com/NousResearch/hermes-agent) in a local environment.

> [!NOTE]
> **Personal / Experimental Repository**
> This repository is a personal setup created for testing and experimenting with Hermes Agent and local self-hosted tools. It is not an official project and is provided as-is without warranties or official support.

## Overview

This repository structures configuration files, custom skills, and workspace directories on the host machine while keeping credentials, session histories, and runtime databases out of Git tracking.

## Directory Structure

```text
mi-harmes/
├── hermes-agent/       # Hermes Agent repository (Git submodule)
├── docker-compose.yml  # Container definitions
├── .env.example        # Environment variable template (UID/GID)
├── .gitignore          # Git ignore rules
├── manage.sh           # Service management script
├── config.yaml.example # Configuration template for Hermes Agent
├── data/               # Hermes data directory (/opt/data in container)
│   ├── skills/         # Custom and bundled skills (tracked in Git)
│   ├── memories/       # Agent memory data (ignored)
│   ├── sessions/       # Chat session history (ignored)
│   ├── state.db        # Internal SQLite database (ignored)
│   └── .env            # API keys and provider credentials (ignored)
├── services/           # Self-hosted search and extraction services
│   ├── searxng/        # SearXNG configuration
│   └── firecrawl/      # Firecrawl configuration
└── workspace/          # Working directory (/workspace in container)
```

## Setup

### 1. Initialize Submodule
Clone the repository and initialize the submodule:

```bash
git submodule update --init --recursive
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and adjust UID/GID if necessary (default is 1000):

```bash
cp .env.example .env
```

### 3. Build Container Image
```bash
docker compose build
```

### 4. Initial Configuration
Configure API keys and model providers (stored in `data/.env`):

```bash
docker compose run --rm cli setup
```

## Usage

### CLI (Interactive Chat)
```bash
docker compose run --rm cli
```

### Gateway / Web Dashboard (Background)
```bash
docker compose up -d
```

- Web Dashboard: `http://127.0.0.1:9119`
- View logs: `docker compose logs -f`
- Stop containers: `docker compose down`

## Self-Hosted Search & Extraction Engines

Local services for search and web scraping without external search API costs:

| Service | Function | Port | Start Command |
| :--- | :--- | :--- | :--- |
| **SearXNG** | Keyword search (`web_search`) | `8888` | `./manage.sh searxng up` |
| **Firecrawl** | Web page extraction / Markdown conversion (`web_extract`) | `3002` | `./manage.sh firecrawl up` |

### Hermes Agent Integration
1. **Environment Variables** (`data/.env` or `.env`):
   ```bash
   SEARXNG_URL=http://localhost:8888
   FIRECRAWL_API_URL=http://localhost:3002
   FIRECRAWL_API_KEY=fc-local-key
   ```

2. **Backend Configuration** (`data/config.yaml`):
   Set the following based on `config.yaml.example`:
   ```yaml
   web:
     search_backend: "searxng"
     extract_backend: "firecrawl"
   ```

## Management Script (`./manage.sh`)

Convenience commands for managing all services:

```bash
# Check status
./manage.sh status

# SearXNG
./manage.sh searxng up
./manage.sh searxng down

# Firecrawl (auto-setup on first run)
./manage.sh firecrawl up
./manage.sh firecrawl down

# All services (SearXNG + Firecrawl + Hermes)
./manage.sh all up
./manage.sh all down
```

## Remote Access (SSH Tunnel)

The Web Dashboard binds to `127.0.0.1:9119` by default. To access it from a remote machine, use an SSH tunnel:

```bash
# Forward dashboard port (9119)
ssh -N -L 9119:localhost:9119 <user>@<host>

# Forward both dashboard (9119) and API server (8642)
ssh -N -L 9119:localhost:9119 -L 8642:localhost:8642 <user>@<host>
```

After connecting, open `http://localhost:9119` in your local browser.

## Git Tracking Policy

- **Tracked**:
  - `docker-compose.yml`, `.env.example`, `config.yaml.example`, `.gitignore`, `README.md`, `README.ja.md`, `manage.sh`
  - `data/skills/` (shared skills)
- **Ignored**:
  - `.env`, `data/.env` (API keys, credentials)
  - `data/sessions/`, `data/memories/`, `data/state.db*` (runtime database and session history)
  - `workspace/*` (agent-generated files and downloads)

## License

[MIT License](LICENSE)
