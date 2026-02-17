# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`claude-scripts` is a Ruby gem providing CLI utilities that power Claude Code slash commands. The `commands/` directory is symlinked from `~/.claude/commands`, making markdown files here available as `/namespace:command` in Claude Code sessions.

## Build & Install

```bash
# Build and install the gem locally
gem build claude-scripts.gemspec && gem install claude-scripts-*.gem

# Or from source directory during development
bundle install
bundle exec claude-scripts help
```

## Architecture

### Dual-File Command Pattern

Each command requires two files with matching paths:

| File | Purpose |
|------|---------|
| `lib/claude_scripts/<namespace>/<name>.rb` | Ruby implementation (inherits from `Command`) |
| `commands/<namespace>/<name>.md` | Slash command definition (runs the CLI) |

Example: `/git:status` → `commands/git/status.md` → `claude-scripts git status` → `lib/claude_scripts/git/status.rb`

### Creating New Commands

Use the built-in scaffolding:
```bash
claude-scripts commands add <namespace> <name> [description...]
```

This creates both files. Then implement the `run` method in the Ruby class.

### Command Base Class (`lib/claude_scripts/command.rb`)

All commands inherit from `Command` which provides:

**Output helpers:**
- `ok(msg)` / `err(msg)` / `warn(msg)` / `info(msg)` - Formatted status messages
- `title(msg)` - Section header
- `table(headers, rows)` - ASCII table
- `frame(title) { ... }` - Boxed section (CLI::UI)
- `spin(title) { ... }` - Spinner for long operations

**Prompts:**
- `ask(question, default:)` - Text input
- `confirm?(question)` - Yes/no
- `select(question, options)` - Choice menu

**Utilities:**
- `args` - Command arguments array
- `sh(cmd, capture:)` - Shell execution
- `sh!(cmd)` - Returns `[success, output]`
- `read_json(path)` / `write_json(path, data)`
- `claude_dir` / `settings_path` - Claude Code paths
- `home(path)` - Replace home dir with `~`

### Router (`lib/claude_scripts/router.rb`)

Routes CLI arguments to command classes:
- `git status` → `ClaudeScripts::Git::Status`
- `ai sd generate` → `ClaudeScripts::AI::SD::Generate`

Acronyms (`ai`, `sd`, `cf`, `cl`, `ps`, `psn`, `api`, `ui`) stay uppercased in class names.

### Markdown Command Files

Minimal format - the bash block is executed by Claude Code:
```markdown
---
description: Short description for command listing
---
```bash
claude-scripts namespace command $ARGUMENTS
```
```

## Key Namespaces

| Namespace | Purpose |
|-----------|---------|
| `git` | Git workflow shortcuts |
| `docker` | Container management |
| `net` | macOS network switching (wifi/split/iphone modes) |
| `util/tools` | Claude Code permissions management |
| `util/check` | Configuration verification |
| `browse` | Browse plugin management |
| `ai/sd` | Stable Diffusion on junkpile server |
| `cf` | Cloudflare (DNS, Pages) |
| `tengu` | Tengu PaaS operations |
| `sd` | Website deployment |
| `commands` | Self-scaffolding |

## Dependencies

- Ruby >= 3.1
- `cli-ui` gem (Shopify's terminal UI library)
