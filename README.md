# claude-scripts

CLI utilities for Claude Code slash commands.

## Installation

```bash
gem install claude-scripts --source https://github.com/aladac/claude-scripts
```

Or from GitHub directly:

```bash
gem 'claude-scripts', github: 'aladac/claude-scripts'
```

## Usage

```bash
claude-scripts <command> [args]
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
| `util check mcp` | Check MCP configuration |
| `browse check` | Check browse plugin status |
| `browse update` | Update browse plugin |
| `browse reinstall` | Full reinstall of browse plugin |
| `ai sd models` | List SD models on junkpile |
| `ai sd generate <prompt>` | Generate image on junkpile |
| `bump [type]` | Bump project version (patch/minor/major) |

## Development

```bash
bundle install
bundle exec claude-scripts help
```

## License

MIT
