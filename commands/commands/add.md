---
description: Create new slash command
---
```bash
claude-scripts commands add $ARGUMENTS
```

After running the scaffold generator above, implement the command:

1. **Read the generated Ruby file** (path shown in output as `RUBY_FILE=...`)
2. **Implement the `run` method** based on the description provided
3. **Use these helpers** from the `Command` base class:
   - `ok(msg)` - success message (green checkmark)
   - `err(msg)` - error message (red X)
   - `info(msg)` - info message (blue arrow)
   - `warn(msg)` - warning message (yellow)
   - `sh(cmd)` - run shell command with output
   - `args` - array of command arguments
   - `home(path)` - replace home dir with ~
4. **Rebuild the gem** after implementation:
   ```bash
   cd /opt/homebrew/lib/ruby/gems/4.0.0/gems/claude-scripts-0.1.0 && gem build claude-scripts.gemspec && gem install claude-scripts-*.gem
   ```
