# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Overview

**jikko** (実行 - "execution") is a Ruby gem providing CLI utilities that power Claude Code slash commands. Every `/namespace:command` has a matching `jikko namespace command` CLI call.

## Quick Start

```bash
# Build and install
gem build jikko.gemspec && gem install jikko-*.gem

# Install commands to ~/.claude/commands
jikko install

# Run a command
jikko git status
```

## Architecture

### Command Pattern

Each command requires two files:

| File | Purpose |
|------|---------|
| `lib/jikko/<namespace>/<name>.rb` | Ruby implementation (inherits from `Jikko::Command`) |
| `commands/<namespace>/<name>.md` | Slash command definition (invokes CLI) |

Example flow:
```
/git:status → commands/git/status.md → jikko git status → lib/jikko/git/status.rb
```

### Directory Structure

```
jikko/
├── commands/              # Slash command definitions (.md)
│   └── <namespace>/
│       └── <command>.md
├── lib/jikko/             # Ruby implementations
│   ├── command.rb         # Base class for all commands
│   ├── router.rb          # CLI argument routing
│   └── <namespace>/
│       └── <command>.rb
├── exe/jikko              # CLI entrypoint
├── .claude/
│   ├── agents/            # Agent definitions
│   └── scripts/           # Standalone dev scripts (not part of gem)
└── doc/                   # Reference documentation
```

### Creating Commands

```bash
jikko commands add <namespace> <name> [description...]
```

This scaffolds both files. Implement the `run` method in the Ruby class.

### Command Base Class

All commands inherit from `Jikko::Command` which provides:

**Output:**
```ruby
ok(msg)      # ✓ green success
err(msg)     # ✗ red error
warn(msg)    # ✗ yellow warning
info(msg)    # cyan info
muted(msg)   # gray muted text
title(msg)   # bold section header
table(headers, rows)  # formatted table
```

**Interactive:**
```ruby
frame(title) { ... }  # boxed section
spin(title) { ... }   # spinner for operations
ask(question, default:)  # text input
confirm?(question)       # yes/no
select(question, options)  # choice menu
```

**Utilities:**
```ruby
args              # command arguments array
sh(cmd)           # execute shell command
sh!(cmd)          # returns [success, output]
read_json(path)   # parse JSON file
write_json(path, data)  # write JSON file
claude_dir        # ~/.claude path
home(path)        # replace home dir with ~
```

### Router

Routes CLI arguments to command classes:
- `jikko git status` → `Jikko::Git::Status`
- `jikko ai sd generate` → `Jikko::AI::SD::Generate`

Acronyms (`ai`, `sd`, `cf`, `cl`, `psn`, `api`, `ui`) stay uppercased.

### Slash Command Format

```markdown
---
description: Short description for command listing
---
```bash
jikko namespace command $ARGUMENTS
```
```

## Namespaces

| Namespace | Purpose |
|-----------|---------|
| `git` | Git workflow shortcuts |
| `docker` | Container management |
| `net` | macOS network switching |
| `util/tools` | Claude Code permissions |
| `util/check` | Configuration verification |
| `browse` | Browse plugin management |
| `ai/sd` | Stable Diffusion on junkpile |
| `cf` | Cloudflare (DNS, Pages) |
| `tengu` | Tengu PaaS operations |
| `sd` | Website deployment |
| `commands` | Self-scaffolding |

## Development Tools

Standalone scripts in `.claude/scripts/` are separate dev tooling (e.g., ratatui commands). They use `Claude::Generator` base class from `ruby/generator.rb` and are not part of the gem.

## Output Format

Commands output in formats optimized for:
1. **Human readability** - colors, tables, spinners
2. **AI context parsing** - structured, consistent patterns

Prefer tables for structured data. Use `ok`/`err`/`info` for status messages.

## Dependencies

- Ruby >= 3.1
- `cli-ui` gem (Shopify's terminal UI library)
