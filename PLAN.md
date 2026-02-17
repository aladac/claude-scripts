# PLAN: jikko — Claude Code Extension Platform

## Vision

**jikko** (実行 - "execution") is the complete Claude Code extension platform:

| Mode | Usage | Purpose |
|------|-------|---------|
| **CLI** | `jikko <cmd>` | Standard command execution |
| **TUI** | `jikko --tui` | Interactive Ratatui interface |
| **MCP** | `jikko mcp <server>` | Stdio MCP server for Claude tools |
| **Install** | `jikko install` | Manage ~/.claude/ (commands, hooks, agents, skills) |

Merges **hu** (Rust, 47K LOC) + **jikko** (Ruby, 2.5K LOC) into one Rust binary.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         jikko binary                            │
├─────────────┬─────────────┬─────────────┬─────────────┬────────┤
│    CLI      │     TUI     │     MCP     │   Install   │  Hooks │
│  (clap)     │  (ratatui)  │   (stdio)   │  (manage)   │ (gen)  │
├─────────────┴─────────────┴─────────────┴─────────────┴────────┤
│                      Service Layer                              │
│  jira │ gh │ slack │ docker │ cf │ context │ data │ ...       │
├─────────────────────────────────────────────────────────────────┤
│                      Client Layer                               │
│  HTTP (reqwest) │ SSH │ Docker CLI │ AWS SDK │ Shell           │
└─────────────────────────────────────────────────────────────────┘

~/.claude/
├── commands/          # Slash commands (managed by jikko install)
│   └── jikko/         # Auto-generated from CLI structure
├── hooks/             # Event hooks (managed by jikko hooks)
│   ├── PreToolUse/
│   ├── PostToolUse/
│   └── Stop/
├── agents/            # Subagents
├── skills/            # Skill definitions
├── settings.json      # Claude Code settings
└── .mcp.json          # MCP server configuration
```

---

## Core Capabilities

### 1. CLI Mode (Default)
Standard command execution with pretty output.

```bash
jikko jira sprint              # Show sprint board
jikko docker ps                # List containers
jikko cf dns example.com       # Manage DNS
```

### 2. TUI Mode (Interactive)
Full-screen Ratatui interface for complex workflows.

```bash
jikko --tui                    # Launch dashboard
jikko jira --tui               # Interactive sprint board
jikko data --tui               # Session explorer
```

### 3. MCP Servers (Claude Integration)
Stdio MCP servers exposing jikko capabilities as Claude tools.

```bash
jikko mcp context              # Context tracking tools
jikko mcp jira                 # Jira operations
jikko mcp docker               # Docker management
jikko mcp cf                   # Cloudflare operations
jikko mcp git                  # Git workflow tools
```

**MCP Server Architecture:**
```rust
// Each MCP server exposes related tools
pub struct JiraMcpServer {
    service: JiraService,
}

impl McpServer for JiraMcpServer {
    fn tools(&self) -> Vec<Tool> {
        vec![
            Tool::new("jira_sprint", "Get current sprint tickets"),
            Tool::new("jira_ticket", "Get ticket details"),
            Tool::new("jira_search", "Search tickets by JQL"),
            Tool::new("jira_update", "Update ticket status"),
        ]
    }

    async fn call(&self, tool: &str, args: Value) -> Result<Value> {
        match tool {
            "jira_sprint" => self.service.get_sprint().await,
            // ...
        }
    }
}
```

**Configuration in ~/.claude/.mcp.json:**
```json
{
  "mcpServers": {
    "jikko-context": {
      "command": "jikko",
      "args": ["mcp", "context"]
    },
    "jikko-jira": {
      "command": "jikko",
      "args": ["mcp", "jira"]
    },
    "jikko-docker": {
      "command": "jikko",
      "args": ["mcp", "docker"]
    }
  }
}
```

### 4. Install Command (Ecosystem Management)
Manages all Claude Code extension points.

```bash
jikko install run              # Full installation
jikko install commands         # Generate /jikko:* slash commands
jikko install hooks            # Install managed hooks
jikko install mcp              # Configure MCP servers
jikko install agents           # Install agents
jikko install status           # Show what's installed
```

### 5. Hooks Management
Create and manage Claude Code hooks.

```bash
jikko hooks ls                           # List all hooks
jikko hooks add PreToolUse safety        # Create hook
jikko hooks rm PreToolUse safety         # Remove hook
jikko hooks enable/disable <name>        # Toggle hook
```

**Hook Types:**
| Event | Trigger | Use Case |
|-------|---------|----------|
| `PreToolUse` | Before tool execution | Validation, safety checks |
| `PostToolUse` | After tool execution | Logging, context tracking |
| `Stop` | Agent completion | Cleanup, notifications |
| `Notification` | System events | Alerts |

**Example Hook (context tracking):**
```bash
# ~/.claude/hooks/PostToolUse/context-track.sh
#!/bin/bash
if [[ "$TOOL_NAME" == "Read" ]]; then
    jikko context add "$TOOL_INPUT_file_path"
fi
```

---

## MCP Server Architecture

Each MCP server exposes **three primitives**:

| Primitive | Purpose | Example |
|-----------|---------|---------|
| **Tools** | Actions Claude executes | `jira_update_status` |
| **Resources** | Data Claude reads (URI) | `jira://sprint/current` |
| **Prompts** | Reusable templates | `jira-analyze-ticket` |

> **Full design:** See [doc/mcp-design.md](doc/mcp-design.md)

### MCP Server Summary

| Server | Tools | Resources | Prompts | Purpose |
|--------|-------|-----------|---------|---------|
| `context` | check, add, list, clear | `context://files/*` | context-check-before-read | Prevent duplicate reads |
| `memory` | store, recall, search, forget | `memory://subjects/*` | memory-store, memory-recall | Persistent memory |
| `indexer` | index_code, index_docs, search | `index://projects/*` | index-codebase, find-similar | Semantic code search |
| `knowledge` | add, query, delete, infer | `knowledge://triples` | add-fact, query-natural | Knowledge graph |
| `link` | add, find, path, analyze | `link://graph/*` | analyze-file, impact | Relationship tracking |
| `jira` | sprint, ticket, search, update | `jira://sprint/*`, `jira://ticket/*` | analyze-ticket, daily-standup | Jira workflow |
| `gh` | prs, runs, failures, fix | `gh://prs/*`, `gh://runs/*` | review-pr, fix-ci | GitHub workflow |
| `docker` | ps, images, logs, exec | `docker://containers/*` | debug-container | Container mgmt |
| `cf` | dns_list, dns_add, pages | `cf://zones/*`, `cf://pages/*` | audit-dns, setup-domain | Cloudflare |
| `slack` | channels, messages, send | `slack://channels/*` | catch-up, draft-message | Slack ops |
| `git` | status, diff, commit, log | `git://status`, `git://diff` | commit-message | Git workflow |
| `read` | outline, interface, around | `read://outline/*` | read-efficiently | Smart reading |
| `data` | sync, stats, search | `data://sessions/*` | usage-report, find-solution | Analytics |

### Resource URI Pattern

```
{server}://{type}/{identifier}

Examples:
  jira://ticket/ABC-123
  jira://sprint/current
  gh://prs/42
  gh://prs/42/diff
  docker://containers/web-app/logs
  cf://zones/example.com/dns
  context://files
  read://outline/src/main.rs
```

### Prompt Template Pattern

Prompts guide Claude through multi-step workflows:

```
Prompt: jira-analyze-ticket
Arguments: key (required)

1. Read ticket: resource jira://ticket/{{key}}
2. Check linked tickets
3. Review comments
4. Assess clarity and complexity
5. Provide recommendations
```

### Cross-Server Workflows

Prompts can orchestrate multiple servers:

```
Prompt: daily-workflow

1. resource jira://sprint/current     → Today's tickets
2. resource gh://prs                  → PRs needing review
3. resource slack://mentions          → Messages to respond
4. resource gh://failures             → CI issues to fix

→ Consolidated morning summary
```

---

## Phases

### Phase 1: Foundation (3-5 days)
**Goal:** Rename, restructure, basic MCP infrastructure

- [ ] Rename hu → jikko (Cargo.toml, binary, all references)
- [ ] Add dependencies: `ratatui`, `crossterm`, `tower` (for MCP)
- [ ] Create service layer pattern (extract from jira as example)
- [ ] Create `src/mcp/` module structure
- [ ] Implement MCP stdio protocol (JSON-RPC over stdin/stdout)
- [ ] Create first MCP server: `jikko mcp context`
- [ ] Add `--tui` global flag scaffold
- [ ] Create `src/tui/` basic structure

**Deliverable:** `jikko mcp context` works as Claude MCP server

### Phase 2: MCP Servers (5-7 days)
**Goal:** Full MCP coverage for existing modules

- [ ] MCP server trait and registry
- [ ] `jikko mcp jira` - Sprint, tickets, search, update
- [ ] `jikko mcp gh` - PRs, runs, failures
- [ ] `jikko mcp slack` - Channels, messages
- [ ] `jikko mcp read` - Smart file reading tools
- [ ] `jikko mcp data` - Session analytics
- [ ] MCP tool documentation generation
- [ ] Test MCP servers with Claude Code

**Deliverable:** 6+ MCP servers working with Claude

### Phase 3: Install & Hooks (2-3 days)
**Goal:** Full ecosystem management

- [ ] `jikko install run` - Full installation wizard
- [ ] `jikko install commands` - Generate slash commands from CLI
- [ ] `jikko install mcp` - Configure .mcp.json
- [ ] `jikko install hooks` - Install managed hooks
- [ ] `jikko hooks ls/add/rm` - Hook management
- [ ] PreToolUse hook: context check (warn on duplicate reads)
- [ ] PostToolUse hook: context track (record file reads)
- [ ] `jikko install status` - Show installation state

**Deliverable:** `jikko install run` sets up complete Claude Code integration

### Phase 4: Port jikko Commands (3-5 days)
**Goal:** All Ruby jikko functionality in Rust

- [ ] docker module (ps, images) + MCP server
- [ ] net module (switch, auto, config) - macOS only
- [ ] cf module (dns, pages) + MCP server
- [ ] tengu module (status, deploy, init)
- [ ] sd module (update websites)
- [ ] browse module (check, update, reinstall)
- [ ] util module (tools, checks)
- [ ] bump command

**Deliverable:** All jikko commands + MCP equivalents

### Phase 5: TUI Components (3-5 days)
**Goal:** Reusable Ratatui widget library

- [ ] `TableWidget` - Sortable, scrollable, selectable
- [ ] `ListWidget` - Filterable, searchable
- [ ] `StatusBar` - Mode, keybindings, notifications
- [ ] `TabView` - Module navigation
- [ ] `Popup` - Confirmations, errors, help
- [ ] `InputField` - Text input with validation
- [ ] Color theme system
- [ ] Keyboard shortcut overlay

**Deliverable:** Widget library ready for views

### Phase 6: TUI Views (5-7 days)
**Goal:** Interactive TUI for key workflows

- [ ] Dashboard: Module list, stats, quick actions
- [ ] Jira: Sprint board (Kanban), ticket detail
- [ ] GitHub: PR list, CI status tree
- [ ] Docker: Container list, logs viewer
- [ ] Data: Session explorer, usage graphs
- [ ] Cloudflare: DNS editor, Pages status
- [ ] MCP: Server status, tool list

**Deliverable:** Full TUI experience

### Phase 7: Polish (2-3 days)
**Goal:** Production release

- [ ] Shell completions (bash, zsh, fish)
- [ ] `--json` flag for all commands
- [ ] Config file (`~/.config/jikko/config.toml`)
- [ ] Documentation (README, man pages)
- [ ] 100% test coverage
- [ ] CI/CD (GitHub Actions, cargo publish)
- [ ] Homebrew formula

**Deliverable:** v1.0.0 release

### Phase 8: Claude Code Plugin Package (1-2 days)
**Goal:** Package jikko as distributable Claude Code plugin

> **Reference:** Validated against `plugin-dev:plugin-structure`, `plugin-dev:mcp-integration`, `plugin-dev:hook-development` skills

**Plugin Structure:**
```
jikko-plugin/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/                    # Auto-discovered slash commands
│   └── jikko/
│       ├── context.md
│       ├── memory.md
│       ├── index.md
│       └── ...
├── agents/                      # Optional agents
│   └── indexer.md              # Code indexing agent
├── skills/                      # Optional skills
│   └── memory/
│       └── SKILL.md            # Memory management skill
├── hooks/
│   └── hooks.json              # Plugin hooks format (with wrapper)
├── .mcp.json                   # MCP server definitions
└── scripts/                    # Hook helper scripts
    └── context-track.sh
```

**Tasks:**
- [ ] Create `.claude-plugin/plugin.json` manifest
- [ ] Generate `commands/jikko/*.md` slash command stubs
- [ ] Create `hooks/hooks.json` with proper plugin format
- [ ] Configure `.mcp.json` for all MCP servers
- [ ] Add optional agents (indexer, memory assistant)
- [ ] Add optional skills (memory management, code search)
- [ ] `jikko plugin build` - Generate plugin package
- [ ] `jikko plugin validate` - Validate against plugin-dev schema
- [ ] Test plugin installation in fresh Claude Code
- [ ] Document plugin installation in README

**Plugin Manifest Example:**
```json
{
  "name": "jikko",
  "version": "1.0.0",
  "description": "Claude Code extension platform with MCP servers, hooks, and TUI",
  "author": {
    "name": "chi"
  },
  "repository": "https://github.com/aladac/jikko",
  "keywords": ["mcp", "memory", "indexer", "hooks", "tui"]
}
```

**Hooks Format (Plugin):**
```json
{
  "description": "jikko context tracking and indexing hooks",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Read",
        "hooks": [{
          "type": "command",
          "command": "jikko context add \"$TOOL_INPUT_file_path\"",
          "timeout": 5
        }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "jikko index file \"$TOOL_INPUT_file_path\"",
          "timeout": 30
        }]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [{
          "type": "command",
          "command": "jikko memory recall-project",
          "timeout": 10
        }]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [{
          "type": "command",
          "command": "jikko memory save-context",
          "timeout": 30
        }]
      }
    ]
  }
}
```

**Marketplace Publishing:**
```bash
# Add to saiden-dev/claude-plugins marketplace
cd /Users/chi/Projects/claude-plugins
git submodule add git@github.com:aladac/jikko.git plugins/jikko
git commit -m "Add jikko plugin"
git push
```

**User Installation:**
```bash
claude plugin marketplace add https://github.com/saiden-dev/claude-plugins
claude plugin install jikko
```

**Deliverable:** jikko published to `saiden-dev/claude-plugins` marketplace

---

## Effort Estimate

*Adjusted for Claude-assisted development velocity*

| Phase | Duration | Complexity |
|-------|----------|------------|
| 1. Foundation | 3-5 days | High |
| 2. MCP Servers (all 13) | 5-7 days | High |
| 3. Install & Hooks | 2-3 days | Medium |
| 4. Port Commands | 3-5 days | Medium |
| 5. TUI Components | 3-5 days | High |
| 6. TUI Views | 5-7 days | High |
| 7. Polish | 2-3 days | Low |
| 8. Plugin Package | 1-2 days | Medium |
| **Total** | **24-37 days (~5-6 weeks)** | |

**Note:** Memory/Indexer servers require:
- PostgreSQL with pgvector extension (HNSW index)
- Ollama with dual embedding models:
  - `nomic-embed-code` (768-dim) — code indexing, code memories
  - `mxbai-embed-large` (1024-dim) — docs, text memories
- tree-sitter for AST-aware code chunking (8 languages)

---

## Key Dependencies

```toml
[dependencies]
# CLI
clap = { version = "4", features = ["derive"] }

# Async
tokio = { version = "1", features = ["full"] }

# TUI
ratatui = "0.26"
crossterm = "0.27"

# MCP (JSON-RPC over stdio)
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# HTTP clients
reqwest = { version = "0.12", features = ["json"] }
octocrab = "0.44"  # GitHub

# Database (PostgreSQL + pgvector)
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres"] }
pgvector = "0.4"

# Output
comfy-table = "7"
owo-colors = "4"
```

---

## Success Criteria

1. ✅ `jikko mcp <server>` works as Claude MCP server
2. ✅ `jikko install run` sets up complete Claude Code integration
3. ✅ `jikko hooks` manages PreToolUse/PostToolUse hooks
4. ✅ `jikko --tui` launches interactive dashboard
5. ✅ All 50+ commands work in Rust
6. ✅ 100% test coverage
7. ✅ `cargo install jikko` works
8. ✅ Documentation complete
9. ✅ Plugin package validates against `plugin-dev` schema
10. ✅ Plugin installable in Claude Code (local or marketplace)

---

## Non-Goals (v1.0)

- GUI (non-terminal)
- Web interface
- Plugin system (jikko IS the plugin system)
- Windows support (macOS/Linux only)
