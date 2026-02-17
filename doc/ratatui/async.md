# RatatuiRuby Async Operations

Handle slow operations without freezing the UI.

## The Raw Terminal Problem

Inside `RatatuiRuby.run`, the terminal is in raw mode:
- stdin reconfigured for character-by-character input
- stdout carries escape sequences
- External commands expecting normal terminal I/O fail

### What Breaks in Threads

```ruby
# These fail inside a Thread during raw mode:
`git ls-remote --tags origin`           # Returns empty or hangs
IO.popen(["git", "ls-remote", ...])     # Same
Open3.capture2("git", "ls-remote", ...) # Same
```

Commands succeed synchronously but fail asynchronously because threads inherit the parent's raw terminal state.

---

## Solutions

### 1. Pre-Check Before Raw Mode

Run slow operations before entering the TUI:

```ruby
def initialize
  @data = fetch_data  # Runs before RatatuiRuby.run
end

def run
  RatatuiRuby.run do |tui|
    # @data already available
  end
end
```

**Trade-off**: Delays startup.

---

### 2. Process.spawn with File Output

Spawn a separate process before raw mode. Write results to a temp file. Poll for completion.

```ruby
class AsyncChecker
  CACHE_FILE = File.join(Dir.tmpdir, "my_check_result.txt")

  def initialize
    @loading = true
    @result = nil
    @pid = Process.spawn("my-command > #{CACHE_FILE}")
  end

  def loading?
    return false unless @loading

    # Non-blocking poll
    _pid, status = Process.waitpid2(@pid, Process::WNOHANG)
    if status
      @result = File.read(CACHE_FILE).strip
      @loading = false
    end
    @loading
  end

  def result
    @result
  end
end
```

**Key points**:
- `Process.spawn` returns immediately
- Command runs in separate process, not a thread
- Results pass through temp file (avoids pipe/terminal issues)
- `Process::WNOHANG` polls without blocking

---

### 3. Thread for CPU-Bound Work

Ruby threads work for pure computation (no I/O):

```ruby
Thread.new { @result = expensive_calculation }
```

**Never use threads for shell commands in TUI apps.**

---

## Pattern Summary

| Approach | Use Case | Raw Mode Safe? |
|----------|----------|----------------|
| Sync before TUI | Fast checks (<100ms) | Yes |
| Process.spawn + file | Shell commands, network | Yes |
| Thread | CPU-bound Ruby code | Yes |
| Thread + shell | Shell commands | **No** |

---

## Real Example: Background Check

```ruby
class BackgroundCheck
  CACHE_FILE = File.join(Dir.tmpdir, "check_result.txt")

  def initialize(command)
    @command = command
    @loading = true
    @success = nil
    @pid = Process.spawn("#{command} && echo ok > #{CACHE_FILE} || echo fail > #{CACHE_FILE}")
  end

  def loading?
    return false unless @loading

    _pid, status = Process.waitpid2(@pid, Process::WNOHANG)
    if status
      @success = File.read(CACHE_FILE).strip == "ok"
      @loading = false
    end
    @loading
  end

  def success?
    @success
  end
end
```

### In the TUI

```ruby
RatatuiRuby.run do |tui|
  checker = BackgroundCheck.new("curl -s https://api.example.com/health")

  loop do
    tui.draw do |frame|
      status = if checker.loading?
        "Checking... ⏳"
      elsif checker.success?
        "OK ✓"
      else
        "Failed ✗"
      end

      frame.render_widget(
        tui.paragraph(text: status),
        frame.area
      )
    end

    case tui.poll_event
    in { type: :key, code: "q" }
      break
    else
      nil
    end
  end
end
```

---

## Multiple Background Tasks

```ruby
class TaskRunner
  Task = Data.define(:name, :pid, :file, :status) do
    def loading?
      status == :loading
    end
  end

  def initialize
    @tasks = []
  end

  def add(name, command)
    file = File.join(Dir.tmpdir, "task_#{name}.txt")
    pid = Process.spawn("#{command} > #{file} 2>&1")
    @tasks << Task.new(name:, pid:, file:, status: :loading)
  end

  def poll_all
    @tasks = @tasks.map do |task|
      next task unless task.loading?

      _pid, status = Process.waitpid2(task.pid, Process::WNOHANG)
      if status
        task.with(status: status.success? ? :success : :failed)
      else
        task
      end
    end
  end

  def each(&block)
    @tasks.each(&block)
  end
end
```

### Usage

```ruby
runner = TaskRunner.new
runner.add("api", "curl -s https://api.example.com")
runner.add("db", "pg_isready -h localhost")
runner.add("redis", "redis-cli ping")

RatatuiRuby.run do |tui|
  loop do
    runner.poll_all

    tui.draw do |frame|
      items = runner.map do |task|
        icon = case task.status
               when :loading then "⏳"
               when :success then "✓"
               when :failed  then "✗"
               end
        "#{icon} #{task.name}"
      end

      frame.render_widget(tui.list(items:), frame.area)
    end

    break if tui.poll_event == "q"
  end
end
```

---

## Git Credentials Issue

Git/SSH commands that require credentials will hang or fail in raw mode because they try to read from the reconfigured stdin.

**Workaround**: Set `GIT_TERMINAL_PROMPT=0` to prevent prompts (auth fails silently instead of hanging):

```ruby
pid = Process.spawn(
  { "GIT_TERMINAL_PROMPT" => "0" },
  "git ls-remote --tags origin > #{CACHE_FILE}"
)
```
