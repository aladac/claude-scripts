# jikko (実行)

CLI framework for Claude Code slash commands.

## Installation

```bash
gem build jikko.gemspec
gem install jikko-*.gem
```

## Setup

Install commands to `~/.claude/commands`:

```bash
jikko install
```

## Usage

Every slash command has a matching CLI call:

```bash
# /git:status
jikko git status

# /cf:dns zones
jikko cf dns zones

# /ai:sd:generate "a cat"
jikko ai sd generate "a cat"
```

## Commands

| Command | Description |
|---------|-------------|
| `git status` | Show working tree status |
| `git commit` | Stage all and commit with timestamp |
| `git push` | Commit and push |
| `git branches` | List branches by recent commit |
| `docker ps` | List running containers |
| `docker images` | List Docker images |
| `net switch [mode]` | Switch network mode (wifi/split/iphone) |
| `net auto` | Auto-switch based on WiFi availability |
| `util tools ls` | List whitelisted tool permissions |
| `util tools add <perm>` | Add tool permission |
| `util check claude_code` | Check Claude Code configuration |
| `browse check` | Check browse plugin status |
| `browse update` | Update browse plugin |
| `ai sd models` | List SD models on junkpile |
| `ai sd generate <prompt>` | Generate image on junkpile |
| `bump [type]` | Bump project version (patch/minor/major) |
| `install` | Install commands to ~/.claude/commands |

## Creating Commands

```bash
jikko commands add <namespace> <name> [description]
```

This creates:
- `lib/jikko/<namespace>/<name>.rb` - Ruby implementation
- `commands/<namespace>/<name>.md` - Slash command definition

## Development

```bash
bundle install
bundle exec jikko help
```

## License

MIT
