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
6. **Optional Host iptables LAN Isolation**
   - Opt-in command `./manage.sh firewall on` available if L3/L4 packet dropping is desired.

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

### Option A: WebUI + SearXNG ([Recommended] Balanced & Lightweight)
```bash
./manage.sh search up
# Or: docker compose --profile search up -d
```

### Option B: WebUI Only (Minimal Footprint)
```bash
./manage.sh gateway up
# Or: docker compose up -d gateway
```

### Option C: Interactive CLI (TUI Only)
```bash
./manage.sh cli
# Or: docker compose run --rm cli
```

### Option D: Full Stack (With Local Web Extraction)
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

## License

[MIT License](LICENSE)
