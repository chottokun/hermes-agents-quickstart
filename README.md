# hermes-agents-quickstart

[Japanese Document](README.ja.md)

A configuration repository for safely, cleanly, and easily running [Hermes Agent](https://github.com/NousResearch/hermes-agent) locally via Docker Compose.

> [!NOTE]
> **Personal Research & Experimentation Repository**
> This repository is a personal note and configuration record for experimenting with Hermes Agent and local companion services (SearXNG / Firecrawl).
> Provided as-is without SLA for issues or PRs.

> [!TIP]
> **Official Prebuilt Image & Clean-Start Setup**
> Uses the official Docker image (`nousresearch/hermes-agent:latest`) by default. **No source cloning or local build required** — get started in seconds.
> A dedicated build pathway (`./manage.sh build`) is also provided for local customization.

---

## Key Features & Security Design

1. **Non-Invasive to Host OS (No sudo or iptables required)**
   - Operates completely without host OS or network modification, running entirely with non-root user permissions (docker group).
2. **Minimal Port Exposure (WebUI Loopback Only)**
   - Only the WebUI (`127.0.0.1:9119:9119`) is bound to host localhost. No exposure to local LAN.
   - SearXNG (8080), Firecrawl (3002), and Gateway API (8642) are confined to internal bridge container networking (`expose`).
3. **Container Privilege Drop (Principle of Least Privilege)**
   - `security_opt: [no-new-privileges:true]` and dropped capabilities (`NET_RAW`, `NET_ADMIN`, etc.) prevent privilege escalation.
4. **Hermes Agent Built-in SSRF Protection**
   - Built-in validation blocks access to private network CIDRs (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) for web search and scraping tools.
5. **Flexible Compose Profiles**
   - Easily launch Minimal WebUI, Recommended WebUI + SearXNG, CLI TUI, or Full Stack.
6. **Resource Limits & Log Rotation (VPS Stability)**
   - All services define explicit memory limits (preventing host OOM lockups) and log rotation (`max-size: 10m`, `max-file: 3`) to eliminate disk exhaustion risk.

---

## Directory Structure

```text
hermes-agents-quickstart/
├── docker-compose.yml       # Primary Compose file (uses official prebuilt image)
├── docker-compose.build.yml # (Dev) Local build overlay
├── .env.example             # Environment variable template
├── .gitignore               # Git exclusion rules
├── manage.sh                # Unified management script (Profiles / build)
├── config.yaml.example      # Configuration template for Hermes Agent
├── data/                    # Persistent data mount (/opt/data)
├── services/                # Self-hosted search & extract services
│   ├── searxng/             # SearXNG configuration
│   └── firecrawl/           # Firecrawl configuration
└── workspace/               # Host workspace mount (/workspace)
```

---

## Quick Setup (3 Steps)

### 1. Clone Repository
No submodules required:
```bash
git clone https://github.com/chottokun/hermes-agents-quickstart.git
cd hermes-agents-quickstart
```

### 2. Configure Environment
```bash
cp .env.example .env
```
*(Optionally set `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` and `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`)*

### 3. Initial Setup (TUI)
The official image is automatically downloaded:
```bash
./manage.sh setup
```

---

## Launch Options

> [!TIP]
> **One-Command Startup & Resume (`./manage.sh run`)**
> Running `./manage.sh run` (or `./manage.sh up`) automatically **remembers and resumes your previously used profile configuration** (defaults to recommended `search up` on initial run). Day-to-day operation can be done with this single command.

### Option A: Bot Daemon ([Recommended] Discord/Messaging Bot + SearXNG, WebUI Disabled)
Optimal for running Discord or Telegram bots 24/7. Disables the WebUI (headless mode) to **save ~80-150MB of RAM**.
```bash
./manage.sh bot up
# View logs: ./manage.sh bot logs (or docker compose logs -f gateway)
```

### Option B: WebUI + SearXNG (WebUI Dashboard + Web Search)
Access the WebUI (`http://localhost:9119`) in your browser while using SearXNG for web search.
```bash
./manage.sh search up
# Or: docker compose --profile search up -d
```

### Option C: WebUI Only (Minimal Footprint)
```bash
./manage.sh gateway up
# Or: docker compose up -d gateway
```

### Option D: Interactive CLI (TUI)
Run an on-demand terminal session without a persistent WebUI container. Supports integration with SearXNG web search.
```bash
# Standalone CLI session (lightweight, no web search)
./manage.sh cli

# CLI + SearXNG (with integrated web search)
./manage.sh cli search
# Or: ./manage.sh search cli
```

### Option E: Full Stack (With Local Web Extraction)
```bash
./manage.sh full up
```

---

## Developer Guide: Local Source Build

To customize or build from source:
```bash
./manage.sh build
```
* Automatically fetches the `hermes-agent` submodule if missing.
* Builds `hermes-agent:local` via `docker-compose.build.yml`.
* Configures `.env` with `HERMES_IMAGE=hermes-agent:local` seamlessly.

---

## Use Case: 24/7 Messaging Bot Daemon (Discord / Telegram)

After configuring credentials and platform settings in the TUI, Hermes Agent can run as a background daemon (`gateway`) to serve as an always-on Discord or Telegram bot.

### Workflow

1. **Configure Platform Credentials via TUI**
   ```bash
   ./manage.sh setup
   # Or: ./manage.sh cli
   ```
   Follow the wizard to input your LLM provider API keys as well as your **Discord Bot Token** and channel settings. All configurations are automatically persisted to `./data`. You can safely exit the TUI session once finished.

2. **Launch as Background Daemon**
   ```bash
   # Bot daemon (WebUI disabled, saves ~100MB RAM, SearXNG search included)
   ./manage.sh bot up

   # Or with WebUI dashboard enabled for browser monitoring
   ./manage.sh search up

   # Or one-command resume:
   ./manage.sh run
   ```
   The `gateway` service starts detached (`-d`), automatically connects to Discord, and begins listening and responding to mentions/messages. With `restart: unless-stopped`, the bot survives VPS reboots automatically.

3. **Monitor Logs & Status**
   ```bash
   # Real-time bot conversation & connection logs
   docker compose logs -f gateway

   # Check container status
   ./manage.sh status
   ```

4. **Stop the Bot Daemon**
   ```bash
   ./manage.sh down
   ```

---

## Stop, Status & Update

```bash
# Check status of running containers
./manage.sh status

# Stop all running services
./manage.sh down

# Update official image to latest
./manage.sh update
```

---

## Remote Access (SSH Tunneling)

The Web Dashboard is bound to `127.0.0.1:9119` and not exposed to the LAN. Access securely from remote machines via an SSH tunnel:

```bash
ssh -N -L 9119:localhost:9119 <user>@<server-host>
```
Then navigate to `http://localhost:9119` in your browser.

---

## Production / VPS Deployment Tips

1. **Change Default Passwords & Secrets**
   When creating your `.env` on a VPS or remote host, generate random strings for:
   - `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`: WebUI Basic Authentication password
   - `SEARXNG_SECRET`: SearXNG session encryption secret (can be set directly in `.env`)

2. **Switching `data/config.yaml` for Full Stack (Firecrawl)**
   The auto-initialized `data/config.yaml` defaults to `extract_backend: "none"` optimized for the lightweight `search` profile.
   When running the full stack with Firecrawl (`./manage.sh full up`), change `extract_backend` to `"firecrawl"` in `data/config.yaml`.

---

## License

[MIT License](LICENSE)
