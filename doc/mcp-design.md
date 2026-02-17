# jikko MCP Server Design

## Overview

Each `jikko mcp <name>` server exposes the full MCP primitive set:

| Primitive | Purpose | Example |
|-----------|---------|---------|
| **Tools** | Actions to execute | `jira_update_status` |
| **Resources** | Data to read (URI-based) | `jira://sprint/current` |
| **Prompts** | Reusable templates | `jira-ticket-analysis` |

```
┌─────────────────────────────────────────────────────────────┐
│                    jikko mcp jira                           │
├─────────────────┬─────────────────┬─────────────────────────┤
│     Tools       │   Resources     │        Prompts          │
├─────────────────┼─────────────────┼─────────────────────────┤
│ jira_sprint     │ jira://sprint/* │ jira-analyze-ticket     │
│ jira_ticket     │ jira://ticket/* │ jira-daily-standup      │
│ jira_search     │ jira://search/* │ jira-sprint-review      │
│ jira_update     │ jira://my/*     │ jira-create-subtasks    │
│ jira_comment    │                 │ jira-estimate           │
└─────────────────┴─────────────────┴─────────────────────────┘
```

---

## MCP Server: context

**Purpose:** Track files already in Claude's context to prevent wasteful re-reads.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `context_check` | Check if file is in context | `path: string` |
| `context_add` | Mark file as read | `path: string, lines?: number` |
| `context_list` | List all context entries | `filter?: string` |
| `context_clear` | Clear context | `pattern?: string` |
| `context_stats` | Context statistics | - |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `context://files` | All tracked files | List of paths with metadata |
| `context://files/{path}` | Single file entry | Read timestamp, line count, token estimate |
| `context://stats` | Context statistics | Total files, tokens, session age |
| `context://recent` | Recently read files | Last 10 files with timestamps |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `context-check-before-read` | Remind to check context before Read tool | `file: string` |
| `context-summary` | Summarize what's in context | - |
| `context-cleanup-suggest` | Suggest files to drop from context | `threshold?: string` |

**Prompt: context-check-before-read**
```
Before reading {{file}}, check if it's already in context:

1. Call context_check with path "{{file}}"
2. If already read, use existing knowledge
3. If not read, proceed with Read tool
4. After reading, call context_add

This saves tokens by avoiding duplicate file reads.
```

---

## MCP Server: jira

**Purpose:** Jira operations for ticket management.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `jira_sprint` | Get current sprint | `board?: string` |
| `jira_ticket` | Get ticket details | `key: string` |
| `jira_search` | Search with JQL | `jql: string, limit?: number` |
| `jira_update` | Update ticket | `key: string, status?: string, assignee?: string` |
| `jira_comment` | Add comment | `key: string, body: string` |
| `jira_create` | Create ticket | `project: string, summary: string, type?: string` |
| `jira_link` | Link tickets | `from: string, to: string, type: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `jira://sprint/current` | Current sprint | Sprint info with all tickets |
| `jira://sprint/{id}` | Specific sprint | Sprint details |
| `jira://ticket/{key}` | Ticket details | Full ticket with comments |
| `jira://ticket/{key}/comments` | Ticket comments | Comment thread |
| `jira://my/tickets` | My assigned tickets | List of tickets |
| `jira://my/recent` | Recently viewed | Last 10 tickets |
| `jira://search/{jql}` | JQL search results | Matching tickets |
| `jira://project/{key}` | Project info | Project details, components |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `jira-analyze-ticket` | Deep analysis of a ticket | `key: string` |
| `jira-daily-standup` | Generate standup summary | `user?: string` |
| `jira-sprint-review` | Sprint retrospective | `sprint?: string` |
| `jira-create-subtasks` | Break ticket into subtasks | `key: string` |
| `jira-estimate` | Estimate story points | `key: string` |
| `jira-find-related` | Find related tickets | `key: string` |
| `jira-write-description` | Generate ticket description | `summary: string` |

**Prompt: jira-analyze-ticket**
```
Analyze Jira ticket {{key}} comprehensively:

1. Read the ticket: resource jira://ticket/{{key}}
2. Check linked tickets and blockers
3. Review comment history
4. Assess:
   - Is the acceptance criteria clear?
   - Are there missing details?
   - What questions should be asked?
   - Estimated complexity (1-5)
5. Provide actionable recommendations
```

**Prompt: jira-daily-standup**
```
Generate daily standup for {{user}}:

1. Get my tickets: resource jira://my/tickets
2. Filter by recent activity (last 24h)
3. Format as:

   **Yesterday:**
   - [TICKET-123] What was done

   **Today:**
   - [TICKET-456] What's planned

   **Blockers:**
   - Any impediments
```

---

## MCP Server: gh

**Purpose:** GitHub operations for PR and CI workflow.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `gh_prs` | List PRs | `repo?: string, state?: string` |
| `gh_pr` | Get PR details | `number: number` |
| `gh_pr_create` | Create PR | `title: string, body: string, base?: string` |
| `gh_pr_merge` | Merge PR | `number: number, method?: string` |
| `gh_runs` | List workflow runs | `repo?: string, workflow?: string` |
| `gh_run` | Get run details | `id: number` |
| `gh_failures` | Get failing checks | `ref?: string` |
| `gh_rerun` | Rerun workflow | `id: number` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `gh://prs` | Open PRs | List with status |
| `gh://prs/{number}` | PR details | Full PR with reviews, checks |
| `gh://prs/{number}/diff` | PR diff | Unified diff |
| `gh://prs/{number}/reviews` | PR reviews | Review comments |
| `gh://runs` | Recent workflow runs | Run list with status |
| `gh://runs/{id}` | Run details | Jobs and steps |
| `gh://runs/{id}/logs` | Run logs | Full log output |
| `gh://failures` | Current failures | Failing checks on default branch |
| `gh://repo` | Repository info | Repo metadata |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `gh-review-pr` | Review a pull request | `number: number` |
| `gh-fix-ci` | Diagnose and fix CI failure | `run_id?: number` |
| `gh-summarize-changes` | Summarize PR changes | `number: number` |
| `gh-create-pr-description` | Generate PR description | - |
| `gh-check-mergeable` | Check if PR is ready to merge | `number: number` |

**Prompt: gh-review-pr**
```
Review PR #{{number}}:

1. Read PR: resource gh://prs/{{number}}
2. Read diff: resource gh://prs/{{number}}/diff
3. Check CI status in PR details
4. For each changed file:
   - Check for bugs, security issues
   - Verify tests exist
   - Check code style
5. Provide review:
   - Summary of changes
   - Issues found (if any)
   - Suggestions
   - Approval recommendation (approve/request changes)
```

**Prompt: gh-fix-ci**
```
Fix CI failure:

1. Get failures: resource gh://failures (or gh://runs/{{run_id}})
2. Read logs: resource gh://runs/{id}/logs
3. Identify failure cause:
   - Test failure → find failing test, read test file
   - Lint error → identify file and rule
   - Build error → check dependencies, syntax
4. Propose fix with code changes
5. Verify fix doesn't break other tests
```

---

## MCP Server: docker

**Purpose:** Docker container and image management.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `docker_ps` | List containers | `all?: boolean` |
| `docker_images` | List images | `filter?: string` |
| `docker_logs` | Get container logs | `container: string, tail?: number` |
| `docker_exec` | Execute command | `container: string, cmd: string` |
| `docker_start` | Start container | `container: string` |
| `docker_stop` | Stop container | `container: string` |
| `docker_restart` | Restart container | `container: string` |
| `docker_inspect` | Inspect container | `container: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `docker://containers` | Running containers | List with status |
| `docker://containers/all` | All containers | Including stopped |
| `docker://containers/{id}` | Container details | Full inspect output |
| `docker://containers/{id}/logs` | Container logs | Recent log output |
| `docker://images` | Local images | Image list with sizes |
| `docker://images/{id}` | Image details | Image inspect |
| `docker://networks` | Docker networks | Network list |
| `docker://volumes` | Docker volumes | Volume list |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `docker-debug-container` | Debug a failing container | `container: string` |
| `docker-optimize-image` | Suggest Dockerfile optimizations | `image: string` |
| `docker-compose-status` | Analyze compose stack | - |
| `docker-cleanup-suggest` | Suggest cleanup actions | - |

**Prompt: docker-debug-container**
```
Debug container {{container}}:

1. Get status: resource docker://containers/{{container}}
2. Read logs: resource docker://containers/{{container}}/logs
3. Check:
   - Exit code and reason
   - Recent log errors
   - Resource usage
   - Network connectivity
4. If running, try:
   - docker_exec with diagnostic commands
5. Provide diagnosis and fix recommendations
```

---

## MCP Server: cf (Cloudflare)

**Purpose:** Cloudflare DNS and Pages management.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `cf_zones` | List zones | - |
| `cf_dns_list` | List DNS records | `zone: string` |
| `cf_dns_add` | Add DNS record | `zone: string, type: string, name: string, content: string` |
| `cf_dns_update` | Update DNS record | `zone: string, id: string, ...fields` |
| `cf_dns_delete` | Delete DNS record | `zone: string, id: string` |
| `cf_pages_list` | List Pages projects | - |
| `cf_pages_deployments` | List deployments | `project: string` |
| `cf_pages_create` | Create project | `name: string, repo?: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `cf://zones` | All zones | Zone list with status |
| `cf://zones/{zone}` | Zone details | Settings, analytics |
| `cf://zones/{zone}/dns` | DNS records | All records |
| `cf://pages` | Pages projects | Project list |
| `cf://pages/{project}` | Project details | Config, deployments |
| `cf://pages/{project}/deployments` | Deployment history | Recent deployments |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `cf-audit-dns` | Audit DNS configuration | `zone: string` |
| `cf-setup-domain` | Setup new domain | `domain: string` |
| `cf-migrate-dns` | Generate migration plan | `from: string, to: string` |

**Prompt: cf-audit-dns**
```
Audit DNS for {{zone}}:

1. Read records: resource cf://zones/{{zone}}/dns
2. Check for:
   - Missing records (MX, SPF, DKIM, DMARC)
   - Duplicate records
   - Invalid TTLs
   - Proxied vs unproxied consistency
   - Security headers (CAA)
3. Provide report with recommendations
```

---

## MCP Server: read

**Purpose:** Smart file reading to minimize token usage.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `read_outline` | File structure outline | `path: string` |
| `read_interface` | Public interface only | `path: string` |
| `read_around` | Lines around match | `path: string, pattern: string, context?: number` |
| `read_diff` | Git diff for file | `path: string, ref?: string` |
| `read_symbols` | List symbols/definitions | `path: string` |
| `read_imports` | List imports/requires | `path: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `read://outline/{path}` | File outline | Structure without bodies |
| `read://interface/{path}` | Public interface | Exported symbols only |
| `read://symbols/{path}` | Symbol list | Functions, classes, etc. |
| `read://diff/{path}` | Uncommitted changes | Diff output |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `read-efficiently` | Guide for token-efficient reading | `path: string` |
| `read-codebase-overview` | Understand a codebase | `root?: string` |

**Prompt: read-efficiently**
```
Read {{path}} efficiently:

1. First, get outline: read_outline("{{path}}")
2. Identify relevant sections from outline
3. If need specific function: read_around("{{path}}", "fn function_name")
4. Only read full file if absolutely necessary
5. After reading, add to context: context_add("{{path}}")

Token savings: outline is typically 10-20% of full file.
```

---

## MCP Server: data

**Purpose:** Claude Code session analytics and search.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `data_sync` | Sync session data | - |
| `data_stats` | Usage statistics | `period?: string` |
| `data_search` | Search sessions | `query: string, limit?: number` |
| `data_session` | Get session details | `id: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `data://stats` | Overall statistics | Token usage, session counts |
| `data://stats/{period}` | Period stats | daily, weekly, monthly |
| `data://sessions` | Recent sessions | Session list |
| `data://sessions/{id}` | Session details | Messages, tools, tokens |
| `data://search/{query}` | Search results | Matching sessions/messages |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `data-usage-report` | Generate usage report | `period?: string` |
| `data-find-solution` | Find past solutions | `problem: string` |
| `data-session-summary` | Summarize a session | `id: string` |

**Prompt: data-find-solution**
```
Find if I've solved "{{problem}}" before:

1. Search sessions: data_search("{{problem}}")
2. For relevant results, read session details
3. Extract:
   - What was the solution?
   - What files were involved?
   - Any gotchas or learnings?
4. Apply to current situation
```

---

## MCP Server: slack

**Purpose:** Slack channel and message operations.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `slack_channels` | List channels | `filter?: string` |
| `slack_messages` | Get messages | `channel: string, limit?: number` |
| `slack_thread` | Get thread | `channel: string, ts: string` |
| `slack_send` | Send message | `channel: string, text: string` |
| `slack_react` | Add reaction | `channel: string, ts: string, emoji: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `slack://channels` | Channel list | Channels with unread counts |
| `slack://channels/{id}` | Channel info | Details, members |
| `slack://channels/{id}/messages` | Recent messages | Message list |
| `slack://threads/{channel}/{ts}` | Thread messages | Full thread |
| `slack://dms` | Direct messages | DM list |
| `slack://mentions` | My mentions | Recent @mentions |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `slack-catch-up` | Summarize channel activity | `channel: string, since?: string` |
| `slack-draft-message` | Draft a message | `context: string` |
| `slack-find-discussion` | Find discussion about topic | `topic: string` |

---

## MCP Server: git

**Purpose:** Git workflow operations.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `git_status` | Working tree status | - |
| `git_diff` | Show diff | `path?: string, staged?: boolean` |
| `git_log` | Commit history | `limit?: number, path?: string` |
| `git_commit` | Create commit | `message: string, files?: string[]` |
| `git_branch` | Branch operations | `name?: string, action?: string` |
| `git_stash` | Stash operations | `action: string, message?: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `git://status` | Working tree status | Changed files |
| `git://diff` | Unstaged diff | Diff output |
| `git://diff/staged` | Staged diff | Diff output |
| `git://log` | Recent commits | Commit list |
| `git://branches` | Branch list | Local and remote |
| `git://stash` | Stash list | Stashed changes |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `git-commit-message` | Generate commit message | - |
| `git-review-changes` | Review uncommitted changes | - |
| `git-branch-cleanup` | Suggest branches to delete | - |

**Prompt: git-commit-message**
```
Generate commit message for current changes:

1. Read staged diff: resource git://diff/staged
2. If nothing staged, read unstaged: resource git://diff
3. Analyze changes:
   - What files changed?
   - What's the nature? (feature, fix, refactor, docs)
   - What's the scope?
4. Generate message:
   - First line: type(scope): description (50 chars)
   - Body: explain why, not what
   - Footer: references (fixes #123)
```

---

## Implementation Notes

### Resource URI Structure

All resources follow pattern: `{server}://{type}/{identifier}`

```rust
pub struct ResourceUri {
    server: String,    // "jira", "gh", "docker", etc.
    path: String,      // "ticket/ABC-123", "prs/42"
}

impl ResourceUri {
    pub fn parse(uri: &str) -> Result<Self> {
        let parts: Vec<&str> = uri.splitn(2, "://").collect();
        Ok(Self {
            server: parts[0].to_string(),
            path: parts[1].to_string(),
        })
    }
}
```

### Prompt Template Format

Prompts use `{{variable}}` syntax for arguments:

```rust
pub struct Prompt {
    name: String,
    description: String,
    arguments: Vec<PromptArgument>,
    template: String,
}

pub struct PromptArgument {
    name: String,
    description: String,
    required: bool,
}
```

### Resource Subscriptions

Resources can be subscribed to for updates:

```rust
// Client subscribes to resource
{ "method": "resources/subscribe", "params": { "uri": "jira://sprint/current" } }

// Server notifies on change
{ "method": "notifications/resources/updated", "params": { "uri": "jira://sprint/current" } }
```

---

## Cross-Server Workflows

Prompts can reference resources from multiple servers:

**Prompt: daily-workflow**
```
Morning workflow:

1. Check Jira sprint: resource jira://sprint/current
2. Check GitHub PRs: resource gh://prs
3. Check Slack mentions: resource slack://mentions
4. Check CI status: resource gh://failures

Provide summary:
- Tickets to work on today
- PRs needing review
- Messages to respond to
- CI issues to fix
```

**Prompt: deploy-checklist**
```
Pre-deployment checklist:

1. Git status clean? resource git://status
2. All tests passing? resource gh://failures
3. PR merged? resource gh://prs
4. Docker images built? resource docker://images
5. Cloudflare ready? resource cf://pages/{project}/deployments

Report any blockers before deploying.
```

---

## MCP Server: memory

**Purpose:** Persistent memory with embeddings and vector search. Remember facts, preferences, patterns across sessions.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    memory server                        │
├─────────────────────────────────────────────────────────┤
│  Embedding: mxbai-embed-large (1024-dim, MTEB 64.68)   │
│  Storage: PostgreSQL + pgvector                        │
│  Index: HNSW for fast approximate nearest neighbor     │
└─────────────────────────────────────────────────────────┘
```

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `memory_store` | Store a memory with embedding | `subject: string, content: string, metadata?: object` |
| `memory_recall` | Recall by semantic similarity | `query: string, limit?: number, subject?: string` |
| `memory_search` | Search by subject/metadata | `subject?: string, limit?: number` |
| `memory_forget` | Delete a memory | `id: string` |
| `memory_list` | List subjects and counts | - |
| `memory_consolidate` | Merge similar memories | `subject?: string, threshold?: number` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `memory://subjects` | All memory subjects | Subject list with counts |
| `memory://recent` | Recent memories | Last N stored memories |
| `memory://subject/{name}` | Memories for subject | All memories in category |
| `memory://search/{query}` | Semantic search | Similar memories |
| `memory://stats` | Memory statistics | Count, storage size, subjects |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `memory-store` | Store information properly | `subject: string, content: string` |
| `memory-recall-context` | Recall relevant memories | `topic: string` |
| `memory-consolidate` | Clean up redundant memories | `subject?: string` |
| `memory-extract` | Extract facts from conversation | - |

**Prompt: memory-store**
```
Store "{{content}}" under subject "{{subject}}":

1. Validate subject follows convention:
   - user.preferences.* - User preferences
   - project.{name}.* - Project-specific
   - code.patterns.* - Code patterns
   - tools.{name}.* - Tool usage
   - facts.{topic}.* - General facts

2. Check for existing similar memories:
   - memory_recall("{{content}}", subject="{{subject}}")
   - If very similar exists, consider updating instead

3. Store with metadata:
   - timestamp: Current time
   - source: conversation/user/extracted
   - confidence: high/medium/low

4. Confirm storage with ID
```

**Prompt: memory-recall-context**
```
Recall relevant context for "{{topic}}":

1. Search memories: memory_recall("{{topic}}", limit=10)
2. Also check related subjects
3. Rank by relevance and recency
4. Summarize relevant facts
5. Note any contradictions
```

### Subject Taxonomy

```
user.
  preferences.{key}     # Editor, theme, workflow
  facts.{key}           # Name, role, team
  patterns.{key}        # Usage patterns

project.{name}.
  notes                 # General notes
  decisions             # ADRs, choices made
  context               # Domain knowledge
  todos                 # Pending items

code.
  patterns.{lang}       # Code patterns
  snippets.{name}       # Reusable code
  errors.{type}         # Error solutions

tools.{name}.
  usage                 # How tool is used
  config                # Tool configuration
  tips                  # Tips and tricks
```

---

## MCP Server: indexer

**Purpose:** Code and document indexing with semantic search. Search codebase by meaning, not just keywords.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    indexer server                       │
├─────────────────────────────────────────────────────────┤
│  Parser: tree-sitter (AST-aware chunking)              │
│  Chunking: Semantic units (functions, classes, blocks) │
│  Embedding: nomic-embed-code (768-dim)                 │
│  Storage: PostgreSQL + pgvector (HNSW index)           │
│  Tables: code_index, doc_index, symbols                │
└─────────────────────────────────────────────────────────┘
```

### AST-Aware Chunking (tree-sitter)

**Why AST?** Fixed-size chunking breaks code structure:

```python
# BAD: 2000-char chunk cuts here ↓
def process_data(items):
    results = []
    for item in it
─────────────────────────────────
ems:                              # Context lost!
        results.append(transform(item))
    return results
```

**AST chunking** respects semantic boundaries:

```
┌─────────────────────────────────────────────┐
│ Chunk 1: Function `process_data`            │
│   - Full function body                      │
│   - Signature preserved                     │
│   - Return type visible                     │
└─────────────────────────────────────────────┘
```

### Supported Languages (tree-sitter)

| Language | Parser | Symbol Extraction |
|----------|--------|-------------------|
| Rust | `tree-sitter-rust` | fn, struct, impl, trait, mod |
| Python | `tree-sitter-python` | def, class, import |
| TypeScript | `tree-sitter-typescript` | function, class, interface |
| JavaScript | `tree-sitter-javascript` | function, class |
| Go | `tree-sitter-go` | func, type, interface |
| Ruby | `tree-sitter-ruby` | def, class, module |
| Java | `tree-sitter-java` | class, method, interface |
| C/C++ | `tree-sitter-c/cpp` | function, struct, class |

### Symbol Table

```sql
-- Extracted symbols for link analysis
CREATE TABLE symbols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    path TEXT NOT NULL,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,          -- function, class, struct, etc.
    signature TEXT,              -- Full signature
    start_line INT,
    end_line INT,
    parent_id UUID REFERENCES symbols(id),
    project TEXT,
    indexed_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX symbols_name_idx ON symbols (name);
CREATE INDEX symbols_path_idx ON symbols (path);
CREATE INDEX symbols_kind_idx ON symbols (kind);
```

### Chunking Strategy

```rust
enum ChunkKind {
    Function,      // Whole function/method
    Class,         // Class with methods (if small)
    ClassHeader,   // Class signature + field list (if large)
    Method,        // Individual method (from large class)
    Module,        // Module/file header + imports
    Block,         // Logical block (if, for, match)
}

// Max chunk size: 4000 tokens (~16KB)
// If function > max, split at nested blocks
// Always preserve: signature, docstring, return type
```

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `index_code` | Index code directory | `path: string, project?: string, extensions?: string[]` |
| `index_docs` | Index documentation | `path: string, project?: string` |
| `index_file` | Index single file | `path: string, project?: string` |
| `index_search` | Semantic search | `query: string, type?: code\|docs\|all, project?: string, limit?: number` |
| `index_status` | Show index stats | `project?: string` |
| `index_clear` | Clear index | `project?: string, type?: code\|docs\|all` |
| `index_refresh` | Re-index changed files | `project?: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `index://projects` | Indexed projects | Project list with stats |
| `index://project/{name}` | Project details | File count, languages, size |
| `index://project/{name}/files` | Indexed files | File list with chunks |
| `index://search/{query}` | Search results | Matching chunks with paths |
| `index://stats` | Overall stats | Total files, chunks, projects |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `index-codebase` | Index current project | `path?: string` |
| `index-find-similar` | Find similar code | `code: string` |
| `index-find-usage` | Find usage of pattern | `pattern: string` |
| `index-explain` | Explain code section | `path: string, query: string` |

**Prompt: index-codebase**
```
Index the codebase at {{path}}:

1. Determine project name from path or git remote
2. Check current index status: index_status(project)
3. If already indexed, offer to refresh or re-index
4. Index code files: index_code(path, project)
5. Index documentation: index_docs(path, project)
6. Report statistics:
   - Files indexed
   - Chunks created
   - Languages detected
```

**Prompt: index-find-similar**
```
Find code similar to:
```
{{code}}
```

1. Search index: index_search(code, type="code")
2. For top results, show:
   - File path
   - Similarity score
   - Code snippet
3. Note any patterns or duplications
```

### Hook Integration

Index stays fresh via hooks. **Note:** Plugin hooks use wrapper format.

```json
{
  "description": "jikko indexing and context hooks",
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
    ],
    "Stop": [
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

---

## MCP Server: knowledge

**Purpose:** Knowledge graph with subject-predicate-object triples. Store and query structured facts.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `knowledge_add` | Add a triple | `subject: string, predicate: string, object: string, metadata?: object` |
| `knowledge_query` | Query triples | `subject?: string, predicate?: string, object?: string` |
| `knowledge_delete` | Delete triple(s) | `subject?: string, predicate?: string, object?: string` |
| `knowledge_infer` | Derive new facts | `depth?: number` |
| `knowledge_export` | Export graph | `format?: json\|turtle\|dot` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `knowledge://triples` | All triples | Triple list |
| `knowledge://subjects` | All subjects | Subject list |
| `knowledge://predicates` | All predicates | Predicate list |
| `knowledge://graph/{subject}` | Subgraph for subject | Related triples |
| `knowledge://stats` | Graph statistics | Triple count, subjects, predicates |

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `knowledge-add-fact` | Add structured fact | `statement: string` |
| `knowledge-query-natural` | Query in natural language | `question: string` |
| `knowledge-visualize` | Generate graph visualization | `subject?: string` |

**Prompt: knowledge-add-fact**
```
Convert "{{statement}}" to knowledge triple:

1. Parse the statement into subject-predicate-object
2. Normalize entities (consistent naming)
3. Check for existing related facts
4. Add triple: knowledge_add(subject, predicate, object)
5. Consider inverse relationships

Examples:
- "Python is a programming language"
  → (Python, is_a, programming_language)
- "The API uses JWT for auth"
  → (API, uses, JWT), (JWT, purpose, authentication)
```

### Triple Conventions

```
Predicates:
  is_a           # Type relationship
  has            # Possession
  uses           # Usage relationship
  depends_on     # Dependency
  related_to     # General relation
  part_of        # Composition
  created_by     # Authorship
  located_in     # Location
  version        # Version info

Subjects/Objects:
  Use PascalCase for entities
  Use snake_case for values
  Prefix with namespace: project.Name, tool.Name
```

---

## MCP Server: link

**Purpose:** Track relationships between files, symbols, and concepts. Navigate codebase by connections.

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `link_add` | Add a link | `from: string, to: string, type: string, metadata?: object` |
| `link_find` | Find links | `node: string, type?: string, direction?: in\|out\|both` |
| `link_path` | Find path between nodes | `from: string, to: string, max_depth?: number` |
| `link_analyze` | Analyze file dependencies | `path: string` |
| `link_orphans` | Find unlinked nodes | `type?: string` |

### Resources

| URI Pattern | Description | Returns |
|-------------|-------------|---------|
| `link://graph` | Full link graph | All links |
| `link://node/{id}` | Links for node | In/out links |
| `link://types` | Link types | Type list with counts |
| `link://stats` | Graph statistics | Nodes, edges, clusters |

### Link Types

```
imports        # File imports another
calls          # Function calls function
implements     # Class implements interface
extends        # Class extends class
references     # Code references symbol
documents      # Doc describes code
tests          # Test covers code
configures     # Config affects component
```

### Prompts

| Name | Description | Arguments |
|------|-------------|-----------|
| `link-analyze-file` | Analyze file relationships | `path: string` |
| `link-find-dependents` | Who depends on this? | `path: string` |
| `link-impact` | Impact analysis for change | `path: string` |

**Prompt: link-impact**
```
Analyze impact of changing {{path}}:

1. Find all dependents: link_find(path, direction="in")
2. For each dependent:
   - Check link type (imports, calls, tests)
   - Assess impact level (breaking, behavioral, cosmetic)
3. Find test coverage: link_find(path, type="tests")
4. Report:
   - Files that need review
   - Tests that should pass
   - Potential breaking changes
```

---

## Hook-Driven Features

Hooks automatically maintain indexes and memory. All hooks are defined in `hooks/hooks.json` using the **plugin format** (with `{"hooks": {...}}` wrapper).

### Hook Event Summary

| Event | Matcher | Command | Purpose |
|-------|---------|---------|---------|
| `PostToolUse` | `Read` | `jikko context add` | Track files in context |
| `PostToolUse` | `Write\|Edit` | `jikko index file` | Re-index modified files |
| `SessionStart` | `*` | `jikko memory recall-project` | Load relevant memories |
| `PreCompact` | `*` | `jikko memory save-context` | Save before compaction |
| `Stop` | `*` | `jikko memory save-context` | Save on session end |

### Context Tracking (PostToolUse/Read)
```bash
# Track files read into context
jikko context add "$TOOL_INPUT_file_path"
```

### Index Updates (PostToolUse/Write|Edit)
```bash
# Re-index modified files
jikko index file "$TOOL_INPUT_file_path"
```

### Memory Save (PreCompact, Stop)
```bash
# Save important context before compaction
jikko memory save-context
```

### Session Memory (SessionStart)
```bash
# Load relevant memories for project
jikko memory recall-project
```

### Timeout Guidelines

| Operation | Timeout | Rationale |
|-----------|---------|-----------|
| Context add | 5s | Fast file metadata lookup |
| Index file | 30s | AST parsing + embedding generation |
| Memory recall | 10s | Vector search + formatting |
| Memory save | 30s | Conversation extraction + embedding |

---

## Storage Backend: PostgreSQL + pgvector

All vector storage uses PostgreSQL with pgvector extension:

```
┌─────────────────────────────────────────────────────────┐
│                   PostgreSQL + pgvector                 │
├─────────────────────────────────────────────────────────┤
│  Extension: pgvector with HNSW indexing                │
│  Performance: <50ms @ 1M vectors (768-dim)             │
│  Concurrency: Full MVCC, multi-writer                  │
│  Sharing: Network accessible (team memory)             │
└─────────────────────────────────────────────────────────┘
```

### Configuration

```toml
# ~/.config/jikko/config.toml
[database]
host = "localhost"        # or "junkpile" for remote
port = 5432
database = "jikko"
user = "jikko"

[embedding]
provider = "ollama"
model = "mxbai-embed-large"   # Best free 1024-dim model (MTEB 64.68)
dimensions = 1024
```

### Embedding Models

Task-specific models outperform general-purpose by 15-20%:

| Task | Model | Dims | Why |
|------|-------|------|-----|
| **Code index** | `nomic-embed-code` | 768 | Trained on code syntax, AST |
| **Doc index** | `mxbai-embed-large` | 1024 | Best general text MTEB |
| **Code memory** | `nomic-embed-code` | 768 | Code patterns, APIs |
| **Text memory** | `mxbai-embed-large` | 1024 | Conversational, facts |

```bash
# Install both
ollama pull nomic-embed-code     # Code-optimized
ollama pull mxbai-embed-large    # Text-optimized
```

```toml
# ~/.config/jikko/config.toml
[embedding.code]
model = "nomic-embed-code"
dimensions = 768

[embedding.text]
model = "mxbai-embed-large"
dimensions = 1024
```

### Why Two Models?

- **Code** has syntax, control flow, variable dependencies — general models miss these
- **Text** has natural language patterns — code models underperform here
- Storage cost is minimal (separate columns in pgvector)
- Query routing is automatic (code_index uses code model, memories use text model)

### Schema

```sql
-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Memories table (text model: 1024-dim)
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'text',  -- 'text' or 'code'
    embedding vector(1024),             -- mxbai-embed-large
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX memories_embedding_idx ON memories
    USING hnsw (embedding vector_cosine_ops);

-- Code memories (code model: 768-dim)
CREATE TABLE code_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768),              -- nomic-embed-code
    language TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX code_memories_embedding_idx ON code_memories
    USING hnsw (embedding vector_cosine_ops);

-- Code index (code model: 768-dim)
CREATE TABLE code_index (
    id TEXT PRIMARY KEY,
    path TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768),              -- nomic-embed-code
    language TEXT,
    project TEXT,
    indexed_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX code_embedding_idx ON code_index
    USING hnsw (embedding vector_cosine_ops);

-- Document index (text model: 1024-dim)
CREATE TABLE doc_index (
    id TEXT PRIMARY KEY,
    path TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1024),             -- mxbai-embed-large
    project TEXT,
    indexed_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX doc_embedding_idx ON doc_index
    USING hnsw (embedding vector_cosine_ops);

-- Knowledge triples
CREATE TABLE knowledge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject TEXT NOT NULL,
    predicate TEXT NOT NULL,
    object TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX knowledge_subject_idx ON knowledge (subject);
CREATE INDEX knowledge_predicate_idx ON knowledge (predicate);

-- Links
CREATE TABLE links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_node TEXT NOT NULL,
    to_node TEXT NOT NULL,
    link_type TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX links_from_idx ON links (from_node);
CREATE INDEX links_to_idx ON links (to_node);
```

### Why PostgreSQL Only

1. **Performance**: HNSW index = <50ms at 1M vectors vs 8s with sqlite-vec
2. **Concurrency**: Multi-writer, no file locking issues
3. **Sharing**: Team can share memory/knowledge across machines
4. **Maturity**: Battle-tested, well-documented
5. **Simplicity**: One backend to maintain, not two

---

## Plugin Distribution

jikko can be packaged as a Claude Code plugin for easy installation.

### Plugin Structure

```
jikko-plugin/
├── .claude-plugin/
│   └── plugin.json              # Required: plugin manifest
├── commands/                    # Auto-discovered slash commands
│   └── jikko/
│       ├── context.md           # /jikko:context
│       ├── memory.md            # /jikko:memory
│       ├── index.md             # /jikko:index
│       └── ...
├── agents/                      # Optional agents
│   └── indexer.md              # Code indexing agent
├── skills/                      # Optional skills
│   └── memory/
│       └── SKILL.md            # Memory management skill
├── hooks/
│   └── hooks.json              # Plugin hooks (wrapper format)
├── .mcp.json                   # MCP server definitions
└── scripts/                    # Hook helper scripts
```

### Plugin Manifest (.claude-plugin/plugin.json)

```json
{
  "name": "jikko",
  "version": "1.0.0",
  "description": "Claude Code extension platform with MCP servers, hooks, and TUI",
  "author": {
    "name": "chi",
    "url": "https://github.com/aladac"
  },
  "repository": "https://github.com/aladac/jikko",
  "keywords": ["mcp", "memory", "indexer", "knowledge", "hooks", "tui"]
}
```

### MCP Configuration (.mcp.json)

```json
{
  "jikko-context": {
    "command": "jikko",
    "args": ["mcp", "context"]
  },
  "jikko-memory": {
    "command": "jikko",
    "args": ["mcp", "memory"]
  },
  "jikko-indexer": {
    "command": "jikko",
    "args": ["mcp", "indexer"]
  },
  "jikko-knowledge": {
    "command": "jikko",
    "args": ["mcp", "knowledge"]
  },
  "jikko-link": {
    "command": "jikko",
    "args": ["mcp", "link"]
  },
  "jikko-jira": {
    "command": "jikko",
    "args": ["mcp", "jira"],
    "env": {
      "JIRA_HOST": "${JIRA_HOST}",
      "JIRA_EMAIL": "${JIRA_EMAIL}",
      "JIRA_TOKEN": "${JIRA_TOKEN}"
    }
  },
  "jikko-gh": {
    "command": "jikko",
    "args": ["mcp", "gh"]
  },
  "jikko-docker": {
    "command": "jikko",
    "args": ["mcp", "docker"]
  },
  "jikko-cf": {
    "command": "jikko",
    "args": ["mcp", "cf"],
    "env": {
      "CF_API_TOKEN": "${CF_API_TOKEN}"
    }
  },
  "jikko-slack": {
    "command": "jikko",
    "args": ["mcp", "slack"],
    "env": {
      "SLACK_TOKEN": "${SLACK_TOKEN}"
    }
  },
  "jikko-git": {
    "command": "jikko",
    "args": ["mcp", "git"]
  },
  "jikko-read": {
    "command": "jikko",
    "args": ["mcp", "read"]
  },
  "jikko-data": {
    "command": "jikko",
    "args": ["mcp", "data"]
  }
}
```

### Prerequisites

Document in plugin README:

```markdown
## Prerequisites

1. **jikko binary** installed and in PATH:
   ```bash
   cargo install jikko
   ```

2. **PostgreSQL** with pgvector extension:
   ```bash
   # macOS
   brew install postgresql@16 pgvector

   # Create database
   createdb jikko
   psql jikko -c "CREATE EXTENSION vector"
   ```

3. **Ollama** with embedding models:
   ```bash
   ollama pull nomic-embed-code     # Code (768-dim)
   ollama pull mxbai-embed-large    # Text (1024-dim)
   ```

4. **Initialize database**:
   ```bash
   jikko db init
   ```
```

### Validation

Before publishing, validate against plugin-dev schema:

```bash
jikko plugin validate
```

Checklist:
- [ ] `plugin.json` has required `name` field
- [ ] All MCP servers use stdio type (system binary)
- [ ] Hooks use plugin wrapper format (`{"hooks": {...}}`)
- [ ] Environment variables documented
- [ ] No hardcoded paths
- [ ] All commands have matching CLI implementation

---

## Marketplace Distribution

jikko will be published to the `saiden-dev/claude-plugins` marketplace.

### Marketplace Structure

```
claude-plugins/                    # Marketplace repo
├── .claude-plugin/
│   └── plugin.json               # Marketplace manifest
├── plugins/
│   ├── browse/                   # git submodule → saiden-dev/browse
│   ├── psn/                      # git submodule → aladac/psn
│   └── jikko/                    # git submodule → aladac/jikko
└── README.md                     # Plugin listing
```

### Publishing to Marketplace

```bash
# 1. Ensure jikko-plugin repo exists and is valid
cd /path/to/jikko
jikko plugin validate

# 2. Add to marketplace as submodule
cd /Users/chi/Projects/claude-plugins
git submodule add git@github.com:aladac/jikko.git plugins/jikko
git commit -m "Add jikko plugin"
git push

# 3. Update marketplace README with jikko commands
```

### Installation

Users install from marketplace:

```bash
# Add marketplace (if not already added)
claude plugin marketplace add https://github.com/saiden-dev/claude-plugins

# List available plugins
claude plugin marketplace list

# Install jikko
claude plugin install jikko
```

### Marketplace README Entry

Add to `/Users/chi/Projects/claude-plugins/README.md`:

```markdown
| [jikko](https://github.com/aladac/jikko) | Claude Code extension platform with MCP servers, hooks, and TUI |

### jikko

| MCP Server | Tools | Purpose |
|------------|-------|---------|
| `jikko-context` | check, add, list, clear | Prevent duplicate file reads |
| `jikko-memory` | store, recall, search | Persistent semantic memory |
| `jikko-indexer` | index, search | AST-aware code search |
| `jikko-knowledge` | add, query, infer | Knowledge graph |
| `jikko-link` | add, find, path | Relationship tracking |
| `jikko-jira` | sprint, ticket, update | Jira workflow |
| `jikko-gh` | prs, runs, fix | GitHub workflow |
| `jikko-docker` | ps, logs, exec | Container management |
| `jikko-cf` | dns, pages | Cloudflare operations |
| `jikko-slack` | channels, send | Slack operations |
| `jikko-git` | status, diff, commit | Git workflow |
| `jikko-read` | outline, interface | Smart file reading |
| `jikko-data` | stats, search | Session analytics |
```
