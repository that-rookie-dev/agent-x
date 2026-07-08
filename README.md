<p align="center">
  <br/>
  <strong>AGENT-X</strong>
  <br/>
  <em>Your AI Wingman</em>
  <br/><br/>
  Multi-provider AI agent in your terminal. 80+ tools. Session persistence. Crew-based sub-agents.
  <br/>
  One command to launch. Zero configuration required.
  <br/><br/>
  <a href="#installation">Install</a> · <a href="#features">Features</a> · <a href="#commands">Commands</a> · <a href="#providers">Providers</a>
</p>

---

## Overview

Agent-X is an autonomous AI agent that lives in your terminal. It connects to multiple AI providers, wields 80+ built-in tools, remembers context across sessions, and supports crew-based sub-agents for delegated expertise — all wrapped in a deep-space-themed interface that makes every interaction feel like commanding a starship.

No cloud accounts. No subscriptions. Bring your own API keys and launch.

---

## Installation

**macOS / Linux (server — headless Web UI):**
```bash
curl -fsSL https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/install-server.sh | bash
agentx start
```

The `install-server.sh` and `install.sh` scripts both install the server package. Desktop app users should use `install-desktop.sh` instead.

**Windows (PowerShell):**
```powershell
powershell -c "irm https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/install.ps1 | iex"
agentx start
```

**Requirements:** Node.js >= 20 (the only prerequisite). The installer handles everything else.

After installation:

```bash
agentx start    # start headless server + Web UI
agentx status   # check health
```

Open the Web UI at http://127.0.0.1:3333 (or your server IP).

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/uninstall.sh | bash
```

---

## Features

### Multi-Provider AI

Switch between providers mid-conversation. No restart needed.

| Provider | Models |
|----------|--------|
| OpenAI | GPT-4o, o1, o3 |
| Anthropic | Claude 3.5, Claude 4 |
| Google | Gemini |
| Ollama | Any local model |
| LM Studio | Any local model |

### 80+ Built-in Tools

Agent-X does not just talk — it acts. Tools are organized by domain:

- **Filesystem** — read, write, move, delete, search files and directories
- **Shell** — execute commands, manage background processes
- **Git** — status, diff, log, commit, branch, stash, blame
- **Code Intelligence** — search symbols, find definitions, replace, refactor
- **Packages** — install, remove, list, outdated, run scripts
- **Testing** — run suites, watch mode, coverage, generate tests
- **Web / HTTP** — GET, POST, scrape, search the web
- **Browser Automation** — open pages, click elements, screenshots, evaluate JS
- **Containers** — Docker lifecycle, compose, logs, exec
- **Database** — query, inspect schema, export data
- **GitHub** — issues, PRs, repos, workflows, releases
- **System** — disk, ports, env, processes, security audit
- **MCP** — connect to any Model Context Protocol server for extended capabilities

### Permission System

Every tool action passes through a clearance gate:

- Scope-based path validation
- Risk-level assessment per tool
- Interactive prompts — allow once, allow always, or deny
- Full audit trail of approved actions

### Session Persistence

- Auto-save on every turn
- Crash recovery — pick up exactly where you left off
- Token tracking and context management
- Session compaction when context grows large

### Crews (Sub-Agents)

Define specialized crew members with distinct personalities, expertise, and system prompts. Agent-X auto-delegates relevant tasks to the right crew member based on the conversation context.

```bash
/crew list                  # List all crew members
/crew create                # Create a new crew member
/crew switch <name>         # Switch active crew
/crew show <name>           # View crew details
```

Crews can be @-mentioned by callsign during conversation to direct them explicitly. No default crew — zero crews is valid.

### Daemon Mode & Web-UI

Run Agent-X as a background daemon and interact via your browser or the terminal. The daemon starts without requiring any bridge configuration.

```bash
agentx start      # launch the background daemon
agentx status     # check daemon health
agentx stop       # terminate the daemon
```

The Web-UI is available at `http://localhost:3333` whenever the daemon is running — no separate setup needed.

On server installs, the Web UI is also reachable at `http://<your-server-ip>:3333` (binds to `0.0.0.0` by default). Override with `AGENTX_HOST` and `AGENTX_PUBLIC_URL` if needed.

Optional bridges (Telegram, Discord, Slack, Email) can be configured after startup via the Web-UI Channels panel or in-terminal commands.

---

## Commands

All configuration and control happens inside the Agent-X terminal:

| Command | Description |
|---------|-------------|
| `/help` | Show all available commands |
| `/model <name>` | Switch AI model |
| `/provider <name>` | Switch provider |
| `/crew` | Manage crews (sub-agents) |
| `/tools` | Browse and search available tools |
| `/permissions` | Review and manage tool permissions |
| `/sessions` | List saved sessions and restore |
| `/fork` | Fork the current session into a new one |
| `/export` | Export session as markdown or JSONL |
| `/remember` | Save a fact to long-term memory |
| `/telegram start <token>` | Connect Telegram bot bridge |
| `/telegram stop` | Disconnect Telegram bridge |
| `/telegram status` | Check Telegram bridge status |
| `/schedule` | Manage scheduled/cron tasks |
| `/plan` | Toggle plan mode (approve steps before execution) |
| `/search` | Semantic codebase search using RAG |
| `/clear` | Clear message history |
| `/theme` | Change or persist UI theme |
| `/exit` | Exit Agent-X |

---

## Providers

Agent-X works with any OpenAI-compatible API. Configure multiple providers and switch between them freely:

```
/provider openai
/model gpt-4o

/provider anthropic
/model claude-sonnet-4-20250514

/provider ollama
/model llama3
```

Local models via Ollama and LM Studio require no API key — just a running server.

---

## Supported Platforms

| Platform | Architecture |
|----------|-------------|
| macOS | Apple Silicon (arm64) |
| macOS | Intel (x64 via Rosetta) |
| Linux | x64 |
| Linux | arm64 |
| Windows | x64 |

---

## Version Pinning

Install a specific version:

```bash
AGENTX_VERSION=v0.1.0 curl -fsSL https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/install.sh | bash
```

---

## Philosophy

Agent-X is built on three principles:

1. **Autonomy with accountability** — The agent acts independently but never bypasses your clearance. Every destructive or sensitive action requires explicit approval.

2. **Local-first** — Your data stays on your machine. Sessions, memories, and configuration never leave your system. Nothing phones home.

3. **Provider-agnostic** — No lock-in. Swap between cloud and local models at will. The same tools and workflows work regardless of the AI backend.

---

<p align="center">
  <em>Ground control to Major — systems nominal.</em>
</p>
