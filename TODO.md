# TODO: jikko — Claude Code Extension Platform

## Phase 1: Foundation (2-3 weeks)

### Rename & Restructure
- [ ] Rename hu → jikko in Cargo.toml
- [ ] Rename binary from `hu` to `jikko`
- [ ] Update all internal references (use statements, docs)
- [ ] Update README.md for jikko branding

### Dependencies
- [ ] Add `ratatui = "0.26"`
- [ ] Add `crossterm = "0.27"`
- [ ] Add `sqlx` with postgres feature
- [ ] Add `pgvector` crate for vector types
- [ ] Add `tree-sitter` and language parsers
- [ ] Verify tokio features for MCP stdio

### Database Setup
- [ ] PostgreSQL connection pool (sqlx)
- [ ] pgvector extension check/create
- [ ] Schema migrations (memories, code_index, doc_index, knowledge, links)
- [ ] HNSW index creation
- [ ] `jikko db init` command
- [ ] `jikko db status` command

### Service Layer Pattern
- [ ] Extract `JiraService` trait from jira module
- [ ] Create `src/service.rs` with common traits
- [ ] Refactor jira to use service pattern
- [ ] Document service pattern for other modules

### MCP Infrastructure
- [ ] Create `src/mcp/mod.rs`
- [ ] Create `src/mcp/protocol.rs` - JSON-RPC types
- [ ] Create `src/mcp/server.rs` - Stdio server loop
- [ ] Create `src/mcp/types.rs` - Tool, Resource definitions
- [ ] Implement `McpServer` trait
- [ ] Add `jikko mcp` subcommand to CLI

### First MCP Server: Context
- [ ] Create `src/mcp/servers/context.rs`
- [ ] Tool: `context_check` - Check if file in context
- [ ] Tool: `context_add` - Add file to context
- [ ] Tool: `context_list` - List context files
- [ ] Tool: `context_clear` - Clear context
- [ ] Test with Claude Code

### TUI Scaffold
- [ ] Create `src/tui/mod.rs`
- [ ] Create `src/tui/app.rs` - App struct placeholder
- [ ] Add `--tui` flag to Cli (disabled initially)

## Phase 2: MCP Servers (2-3 weeks)

> **Design doc:** [doc/mcp-design.md](doc/mcp-design.md)

### MCP Infrastructure
- [ ] Create server registry pattern
- [ ] `jikko mcp list` - List available servers
- [ ] `jikko mcp <name> --help` - Server documentation
- [ ] Resource URI parser (`{server}://{type}/{id}`)
- [ ] Prompt template engine (`{{variable}}` syntax)
- [ ] Resource subscription support

### Context MCP Server
**Tools:**
- [ ] `context_check` - Check if file in context
- [ ] `context_add` - Mark file as read
- [ ] `context_list` - List context entries
- [ ] `context_clear` - Clear context
- [ ] `context_stats` - Statistics

**Resources:**
- [ ] `context://files` - All tracked files
- [ ] `context://files/{path}` - Single entry
- [ ] `context://stats` - Statistics
- [ ] `context://recent` - Recent files

**Prompts:**
- [ ] `context-check-before-read` - Pre-read reminder
- [ ] `context-summary` - What's in context
- [ ] `context-cleanup-suggest` - Suggest drops

### Jira MCP Server
**Tools:**
- [ ] `jira_sprint` - Get current sprint
- [ ] `jira_ticket` - Get ticket by key
- [ ] `jira_search` - Search by JQL
- [ ] `jira_update` - Update ticket
- [ ] `jira_comment` - Add comment
- [ ] `jira_create` - Create ticket

**Resources:**
- [ ] `jira://sprint/current` - Current sprint
- [ ] `jira://ticket/{key}` - Ticket details
- [ ] `jira://ticket/{key}/comments` - Comments
- [ ] `jira://my/tickets` - My tickets
- [ ] `jira://search/{jql}` - Search results

**Prompts:**
- [ ] `jira-analyze-ticket` - Deep analysis
- [ ] `jira-daily-standup` - Standup summary
- [ ] `jira-sprint-review` - Retrospective
- [ ] `jira-create-subtasks` - Break down ticket
- [ ] `jira-estimate` - Story points

### GitHub MCP Server
**Tools:**
- [ ] `gh_prs` - List PRs
- [ ] `gh_pr` - PR details
- [ ] `gh_pr_create` - Create PR
- [ ] `gh_runs` - Workflow runs
- [ ] `gh_failures` - Failing checks
- [ ] `gh_rerun` - Rerun workflow

**Resources:**
- [ ] `gh://prs` - Open PRs
- [ ] `gh://prs/{number}` - PR details
- [ ] `gh://prs/{number}/diff` - PR diff
- [ ] `gh://runs` - Recent runs
- [ ] `gh://runs/{id}/logs` - Run logs
- [ ] `gh://failures` - Current failures

**Prompts:**
- [ ] `gh-review-pr` - Review pull request
- [ ] `gh-fix-ci` - Diagnose/fix CI failure
- [ ] `gh-summarize-changes` - Summarize PR
- [ ] `gh-create-pr-description` - Generate description

### Docker MCP Server
**Tools:**
- [ ] `docker_ps` - List containers
- [ ] `docker_images` - List images
- [ ] `docker_logs` - Container logs
- [ ] `docker_exec` - Execute command
- [ ] `docker_start/stop/restart` - Container control

**Resources:**
- [ ] `docker://containers` - Running containers
- [ ] `docker://containers/{id}` - Container details
- [ ] `docker://containers/{id}/logs` - Logs
- [ ] `docker://images` - Image list

**Prompts:**
- [ ] `docker-debug-container` - Debug failing container
- [ ] `docker-optimize-image` - Dockerfile suggestions
- [ ] `docker-cleanup-suggest` - Cleanup recommendations

### Cloudflare MCP Server
**Tools:**
- [ ] `cf_zones` - List zones
- [ ] `cf_dns_list` - DNS records
- [ ] `cf_dns_add` - Add record
- [ ] `cf_dns_delete` - Delete record
- [ ] `cf_pages_list` - Pages projects
- [ ] `cf_pages_deployments` - Deployment history

**Resources:**
- [ ] `cf://zones` - Zone list
- [ ] `cf://zones/{zone}/dns` - DNS records
- [ ] `cf://pages` - Pages projects
- [ ] `cf://pages/{project}/deployments` - Deployments

**Prompts:**
- [ ] `cf-audit-dns` - Audit DNS config
- [ ] `cf-setup-domain` - Setup new domain

### Read MCP Server
**Tools:**
- [ ] `read_outline` - File structure
- [ ] `read_interface` - Public interface
- [ ] `read_around` - Lines around match
- [ ] `read_diff` - Git diff
- [ ] `read_symbols` - Symbol list

**Resources:**
- [ ] `read://outline/{path}` - Outline
- [ ] `read://interface/{path}` - Interface
- [ ] `read://symbols/{path}` - Symbols
- [ ] `read://diff/{path}` - Diff

**Prompts:**
- [ ] `read-efficiently` - Token-efficient reading guide
- [ ] `read-codebase-overview` - Understand codebase

### Slack MCP Server
**Tools:**
- [ ] `slack_channels` - List channels
- [ ] `slack_messages` - Get messages
- [ ] `slack_thread` - Get thread
- [ ] `slack_send` - Send message

**Resources:**
- [ ] `slack://channels` - Channel list
- [ ] `slack://channels/{id}/messages` - Messages
- [ ] `slack://mentions` - My mentions

**Prompts:**
- [ ] `slack-catch-up` - Summarize activity
- [ ] `slack-draft-message` - Draft message

### Git MCP Server
**Tools:**
- [ ] `git_status` - Working tree status
- [ ] `git_diff` - Show diff
- [ ] `git_log` - Commit history
- [ ] `git_commit` - Create commit

**Resources:**
- [ ] `git://status` - Status
- [ ] `git://diff` - Unstaged diff
- [ ] `git://diff/staged` - Staged diff
- [ ] `git://log` - Recent commits

**Prompts:**
- [ ] `git-commit-message` - Generate message
- [ ] `git-review-changes` - Review uncommitted

### Data MCP Server
**Tools:**
- [ ] `data_sync` - Sync sessions
- [ ] `data_stats` - Statistics
- [ ] `data_search` - Search sessions
- [ ] `data_session` - Session details

**Resources:**
- [ ] `data://stats` - Overall stats
- [ ] `data://sessions` - Session list
- [ ] `data://sessions/{id}` - Session details

**Prompts:**
- [ ] `data-usage-report` - Usage report
- [ ] `data-find-solution` - Find past solutions

### Memory MCP Server (from psn)
**Infrastructure:**
- [ ] PostgreSQL client with pgvector
- [ ] Dual embedding clients:
  - `mxbai-embed-large` (1024-dim) for text memories
  - `nomic-embed-code` (768-dim) for code memories
- [ ] HNSW index for vector search
- [ ] Auto-detect content type (text vs code)
- [ ] Subject taxonomy validation

**Tools:**
- [ ] `memory_store` - Store with embedding
- [ ] `memory_recall` - Semantic similarity search
- [ ] `memory_search` - Search by subject/metadata
- [ ] `memory_forget` - Delete memory
- [ ] `memory_list` - List subjects and counts
- [ ] `memory_consolidate` - Merge similar memories

**Resources:**
- [ ] `memory://subjects` - Subject list with counts
- [ ] `memory://recent` - Recent memories
- [ ] `memory://subject/{name}` - Memories for subject
- [ ] `memory://search/{query}` - Semantic search
- [ ] `memory://stats` - Statistics

**Prompts:**
- [ ] `memory-store` - Store with proper subject
- [ ] `memory-recall-context` - Recall for topic
- [ ] `memory-consolidate` - Clean up redundant
- [ ] `memory-extract` - Extract facts from conversation

### Indexer MCP Server (from psn)
**Infrastructure:**
- [ ] tree-sitter integration for AST parsing
- [ ] AST-aware chunking (functions, classes, blocks)
- [ ] Symbol extraction (name, kind, signature, lines)
- [ ] symbols table for link analysis
- [ ] code_index table with `nomic-embed-code` (768-dim)
- [ ] doc_index table with `mxbai-embed-large` (1024-dim)
- [ ] HNSW index for vector search (pgvector)
- [ ] Auto-route queries to correct model based on table

**tree-sitter Parsers:**
- [ ] tree-sitter-rust
- [ ] tree-sitter-python
- [ ] tree-sitter-typescript
- [ ] tree-sitter-javascript
- [ ] tree-sitter-go
- [ ] tree-sitter-ruby
- [ ] tree-sitter-java
- [ ] tree-sitter-c / tree-sitter-cpp

**Tools:**
- [ ] `index_code` - Index code directory
- [ ] `index_docs` - Index documentation
- [ ] `index_file` - Index single file
- [ ] `index_search` - Semantic search
- [ ] `index_status` - Show index stats
- [ ] `index_clear` - Clear index
- [ ] `index_refresh` - Re-index changed files

**Resources:**
- [ ] `index://projects` - Indexed projects
- [ ] `index://project/{name}` - Project details
- [ ] `index://project/{name}/files` - Indexed files
- [ ] `index://search/{query}` - Search results
- [ ] `index://stats` - Overall stats

**Prompts:**
- [ ] `index-codebase` - Index current project
- [ ] `index-find-similar` - Find similar code
- [ ] `index-find-usage` - Find usage of pattern
- [ ] `index-explain` - Explain code section

### Knowledge MCP Server (from psn)
**Infrastructure:**
- [ ] Triple storage (subject, predicate, object, metadata)
- [ ] Inference engine (basic)

**Tools:**
- [ ] `knowledge_add` - Add triple
- [ ] `knowledge_query` - Query triples
- [ ] `knowledge_delete` - Delete triple(s)
- [ ] `knowledge_infer` - Derive new facts
- [ ] `knowledge_export` - Export graph

**Resources:**
- [ ] `knowledge://triples` - All triples
- [ ] `knowledge://subjects` - Subject list
- [ ] `knowledge://predicates` - Predicate list
- [ ] `knowledge://graph/{subject}` - Subgraph
- [ ] `knowledge://stats` - Statistics

**Prompts:**
- [ ] `knowledge-add-fact` - Parse and add fact
- [ ] `knowledge-query-natural` - Natural language query
- [ ] `knowledge-visualize` - Generate visualization

### Link MCP Server (from psn)
**Infrastructure:**
- [ ] Link storage (from, to, type, metadata)
- [ ] Graph traversal queries
- [ ] Integration with symbols table (from indexer)
- [ ] Auto-extract links from AST (imports, calls, extends)

**Tools:**
- [ ] `link_add` - Add link
- [ ] `link_find` - Find links for node
- [ ] `link_path` - Find path between nodes
- [ ] `link_analyze` - Analyze file dependencies
- [ ] `link_orphans` - Find unlinked nodes

**Resources:**
- [ ] `link://graph` - Full graph
- [ ] `link://node/{id}` - Links for node
- [ ] `link://types` - Link types
- [ ] `link://stats` - Statistics

**Prompts:**
- [ ] `link-analyze-file` - Analyze relationships
- [ ] `link-find-dependents` - Who depends on this?
- [ ] `link-impact` - Impact analysis

### Testing
- [ ] Unit tests for each server
- [ ] Resource URI parsing tests
- [ ] Prompt template rendering tests
- [ ] Integration test with Claude Code
- [ ] Document MCP server usage

## Phase 3: Install & Hooks (1-2 weeks)

### Install Command
- [ ] `jikko install run` - Full installation wizard
- [ ] `jikko install status` - Show current state
- [ ] `jikko install commands` - Generate slash commands
- [ ] `jikko install mcp` - Configure .mcp.json
- [ ] `jikko install hooks` - Install managed hooks
- [ ] `jikko install agents` - Install agents (if any)

### Slash Command Generation
- [ ] Parse CLI structure to generate commands
- [ ] Template: `commands/jikko/<path>.md`
- [ ] Include `jikko <cmd> $ARGUMENTS` execution
- [ ] Generate skill definitions where appropriate

### MCP Configuration
- [ ] Read existing `.mcp.json`
- [ ] Add/update jikko MCP servers
- [ ] Preserve user's other MCP servers
- [ ] Validate configuration

### Hooks Management
- [ ] `jikko hooks ls` - List all hooks
- [ ] `jikko hooks add <event> <name>` - Create hook
- [ ] `jikko hooks rm <event> <name>` - Remove hook
- [ ] `jikko hooks enable <name>` - Enable hook
- [ ] `jikko hooks disable <name>` - Disable hook
- [ ] `jikko hooks edit <name>` - Open in editor

### Built-in Hooks
- [ ] `context-check` (PreToolUse) - Warn on duplicate file read
- [ ] `context-track` (PostToolUse/Read) - Record file reads
- [ ] `index-update` (PostToolUse/Write|Edit) - Re-index modified files
- [ ] `memory-save` (PreCompact) - Save context before compaction
- [ ] `memory-save` (Stop) - Save context on session end
- [ ] `memory-load` (SessionStart) - Load relevant memories
- [ ] `token-warn` (PostToolUse) - Warn on large responses
- [ ] Document hook creation patterns

## Phase 4: Port jikko Commands (2-3 weeks)

### Docker Module
- [ ] `docker ps` - List containers
- [ ] `docker images` - List images
- [ ] `docker logs <container>` - View logs
- [ ] Docker MCP server with same tools

### Network Module (macOS)
- [ ] `net switch wifi` - WiFi mode
- [ ] `net switch split` - Split tunnel
- [ ] `net switch iphone` - iPhone hotspot
- [ ] `net auto` - Auto-detect and switch
- [ ] `net config` - Show configuration
- [ ] `net check_wifi` - Test connectivity

### Cloudflare Module
- [ ] CF API client with token auth
- [ ] `cf dns <zone>` - List DNS records
- [ ] `cf dns add <zone> <record>` - Add record
- [ ] `cf dns rm <zone> <record>` - Remove record
- [ ] `cf pages list` - List Pages projects
- [ ] `cf pages destroy <project>` - Delete project
- [ ] `cf init_pages <name>` - Create project
- [ ] CF MCP server

### Tengu Module
- [ ] `tengu status` - Deployment status
- [ ] `tengu deploy` - Deploy to Hetzner
- [ ] `tengu init` - Rebuild init

### Site Deployment Module
- [ ] `sd update_saiden` - Deploy saiden.dev
- [ ] `sd update_tengu` - Deploy tengu.to
- [ ] `sd update_tensors` - Deploy tensors
- [ ] `sd update_websites` - Deploy all

### Browse Plugin Module
- [ ] `browse check` - Plugin status
- [ ] `browse update` - Update plugin
- [ ] `browse reinstall` - Full reinstall

### Utility Module
- [ ] `util tools ls` - List permissions
- [ ] `util tools add <perm>` - Add permission
- [ ] `util tools rm <perm>` - Remove permission
- [ ] `util check claude_code` - Check config
- [ ] `util check mcp` - Check MCP config
- [ ] `util sync config` - Sync dotfiles

### Other
- [ ] `bump [patch|minor|major]` - Version bump
- [ ] Git enhancements (if unique to jikko)

## Phase 5: TUI Components (2-3 weeks)

### Core Infrastructure
- [ ] `src/tui/app.rs` - App state, event loop
- [ ] `src/tui/event.rs` - Event handling
- [ ] `src/tui/theme.rs` - Color scheme
- [ ] Terminal setup/cleanup (raw mode, alternate screen)

### Widgets
- [ ] `TableWidget` - Headers, rows, selection
- [ ] `TableWidget` - Scrolling, column sorting
- [ ] `ListWidget` - Items, selection, highlighting
- [ ] `ListWidget` - Filtering, search
- [ ] `StatusBar` - Left/center/right sections
- [ ] `TabView` - Horizontal tabs
- [ ] `Popup` - Centered modal
- [ ] `Popup` - Confirm dialog (y/n)
- [ ] `InputField` - Text with cursor
- [ ] `InputField` - Validation, placeholder
- [ ] `Spinner` - Loading animation

### Navigation
- [ ] j/k or ↑/↓ - Move selection
- [ ] Enter - Select/activate
- [ ] Esc - Back/cancel
- [ ] q - Quit
- [ ] / - Search
- [ ] ? - Help overlay
- [ ] Tab - Next pane

### Testing
- [ ] Widget unit tests
- [ ] Snapshot tests for layouts
- [ ] Event handling tests

## Phase 6: TUI Views (3-4 weeks)

### Dashboard
- [ ] Module list with status
- [ ] Quick stats (sessions, tokens, etc.)
- [ ] Recent activity
- [ ] Quick actions menu

### Jira TUI
- [ ] Sprint board (Kanban columns)
- [ ] Ticket cards (key, summary, status)
- [ ] Ticket detail popup
- [ ] Quick status change
- [ ] Search/filter

### GitHub TUI
- [ ] PR list with status icons
- [ ] PR detail view
- [ ] CI runs tree
- [ ] Failure details with logs

### Docker TUI
- [ ] Container list with status colors
- [ ] Container actions (start/stop/restart)
- [ ] Log viewer with scrolling
- [ ] Image list

### Data TUI
- [ ] Session list
- [ ] Session detail (messages, tools)
- [ ] Usage graph
- [ ] Search

### Cloudflare TUI
- [ ] Zone selector
- [ ] DNS record table (editable)
- [ ] Pages deployment status

### MCP Status TUI
- [ ] Server list with status
- [ ] Tool inventory per server
- [ ] Recent tool calls

## Phase 7: Polish (1-2 weeks)

### Shell Completions
- [ ] Bash completions
- [ ] Zsh completions
- [ ] Fish completions
- [ ] `jikko completions <shell>` command

### Output Modes
- [ ] `--json` flag for all commands
- [ ] `--quiet` flag (errors only)
- [ ] `--verbose` flag (debug info)

### Configuration
- [ ] `~/.config/jikko/config.toml` support
- [ ] Migrate credentials from hu
- [ ] Theme configuration
- [ ] Default mode (cli/tui) setting

### Documentation
- [ ] README.md with examples
- [ ] doc/cli.md - Command reference
- [ ] doc/mcp.md - MCP server guide
- [ ] doc/tui.md - TUI usage
- [ ] doc/hooks.md - Hook development
- [ ] man page generation

### Testing & CI
- [ ] 100% coverage on new code
- [ ] Integration tests
- [ ] GitHub Actions workflow
- [ ] Release automation

### Distribution
- [ ] Cargo.toml metadata
- [ ] `cargo publish` to crates.io
- [ ] Homebrew formula
- [ ] Debian package (cargo-deb)
- [ ] Archive Ruby jikko repo

## Phase 8: Plugin Package (1 week)

> **Validated against:** `plugin-dev:plugin-structure`, `plugin-dev:mcp-integration`, `plugin-dev:hook-development`

### Plugin Structure
- [ ] Create `jikko-plugin/` directory layout
- [ ] Create `.claude-plugin/plugin.json` manifest (name, version, author, keywords)
- [ ] Verify plugin.json only has `name` as required field

### Commands
- [ ] Generate `commands/jikko/*.md` slash command stubs
- [ ] Each command maps to `jikko <cmd> $ARGUMENTS`
- [ ] Pre-allow specific MCP tools in relevant commands

### Hooks Configuration
- [ ] Create `hooks/hooks.json` with **plugin format** (wrapped in `{"hooks": {...}}`)
- [ ] `PostToolUse/Read` → `jikko context add`
- [ ] `PostToolUse/Write|Edit` → `jikko index file`
- [ ] `SessionStart/*` → `jikko memory recall-project`
- [ ] `PreCompact/*` → `jikko memory save-context`
- [ ] `Stop/*` → `jikko memory save-context`
- [ ] Set appropriate timeouts (5-30s based on operation)

### MCP Configuration
- [ ] Create `.mcp.json` at plugin root
- [ ] Configure all 13 MCP servers (stdio type)
- [ ] Document required environment variables

### Optional Components
- [ ] Create `agents/indexer.md` - Code indexing agent
- [ ] Create `skills/memory/SKILL.md` - Memory management skill
- [ ] Create `skills/search/SKILL.md` - Semantic code search skill

### Build & Validate
- [ ] `jikko plugin build` command - Generate plugin package
- [ ] `jikko plugin validate` command - Validate against schema
- [ ] Test plugin in fresh Claude Code installation
- [ ] Verify hooks load correctly (`/hooks` command)
- [ ] Verify MCP servers appear (`/mcp` command)
- [ ] Verify commands appear (slash command autocomplete)

### Documentation
- [ ] Add plugin installation section to README
- [ ] Document required setup (PostgreSQL, Ollama models)
- [ ] Document environment variables
- [ ] Create CHANGELOG.md for plugin releases

### Marketplace Publishing
- [ ] Push jikko plugin repo to `github.com/aladac/jikko`
- [ ] Add as submodule to `claude-plugins`:
  ```bash
  cd /Users/chi/Projects/claude-plugins
  git submodule add git@github.com:aladac/jikko.git plugins/jikko
  ```
- [ ] Update `claude-plugins/README.md` with jikko entry
- [ ] Test installation: `claude plugin install jikko`
- [ ] Verify all MCP servers appear in `/mcp`
- [ ] Verify all hooks load in `/hooks`
- [ ] Verify commands appear in slash autocomplete

---

## Progress Tracker

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 1. Foundation | ⏳ | | |
| 2. MCP Servers | ⏳ | | |
| 3. Install & Hooks | ⏳ | | |
| 4. Port Commands | ⏳ | | |
| 5. TUI Components | ⏳ | | |
| 6. TUI Views | ⏳ | | |
| 7. Polish | ⏳ | | |
| 8. Plugin Package | ⏳ | | |

**Legend:** ⏳ Not started │ 🔄 In progress │ ✅ Complete

---

## Quick Reference

### Start MCP Server
```bash
jikko mcp context    # Context tracking
jikko mcp jira       # Jira operations
jikko mcp docker     # Docker management
```

### Install Everything
```bash
jikko install run    # Full setup wizard
```

### Manage Hooks
```bash
jikko hooks ls                    # List hooks
jikko hooks add PreToolUse safety # Create hook
```

### TUI Mode
```bash
jikko --tui          # Dashboard
jikko jira --tui     # Jira board
```
