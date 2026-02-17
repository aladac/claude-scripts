# RatatuiRuby Testing

Test TUI applications without a real terminal.

## Setup

```ruby
require "ratatui_ruby/test_helper"
require "minitest/autorun"

class MyAppTest < Minitest::Test
  include RatatuiRuby::TestHelper
  # ...
end
```

---

## Test Terminal

Wrap tests in `with_test_terminal` for a headless, in-memory terminal backend.

```ruby
def test_rendering
  # Default: 80x24 terminal
  with_test_terminal do
    widget = Paragraph.new(text: "Hello World")

    RatatuiRuby.draw do |frame|
      frame.render_widget(widget, frame.area)
    end

    assert_includes buffer_content.first, "Hello World"
  end
end

# Custom size
with_test_terminal(40, 10) do
  # 40 columns, 10 rows
end
```

---

## Buffer Inspection

### buffer_content

Returns terminal as array of strings (one per row).

```ruby
with_test_terminal do
  MyApp.new.render

  lines = buffer_content
  assert_equal "Expected text", lines[0].strip
  assert_match /pattern/, lines[1]
end
```

### get_cell

Inspect a single cell's character and style.

```ruby
with_test_terminal do
  MyApp.new.render

  cell = get_cell(0, 0)
  cell.symbol  # => "H"
  cell.fg      # => :red
  cell.bg      # => :black
  cell.bold?   # => true
end
```

### print_buffer

Output buffer to STDOUT with ANSI colors (for debugging).

```ruby
with_test_terminal do
  MyApp.new.render
  print_buffer  # Prints colored output
end
```

---

## Style Assertions

```ruby
# Single cell
assert_fg_color(:red, 0, 0)
assert_bg_color(:blue, 0, 0)
assert_bold(0, 0)

# Area (x, y, width, height)
assert_area_style({ x: 0, y: 0, w: 10, h: 1 }, bg: :blue)
```

---

## Event Injection

Simulate user input without stubbing.

```ruby
with_test_terminal do
  # Single key
  inject_event("key", { code: "q" })

  event = RatatuiRuby.poll_event
  assert_equal "q", event.code
end
```

### Helpers

```ruby
# Multiple keys
inject_keys("hello")

# Key with modifiers
inject_event("key", { code: "c", modifiers: ["ctrl"] })

# Mouse click
inject_click(10, 5, button: "left")
```

---

## Snapshot Testing

Compare screen against stored reference files.

```ruby
with_test_terminal do
  MyApp.new.run
  assert_snapshots("dashboard_view")
end
```

This generates:
- `dashboard_view.txt` — Plain text
- `dashboard_view.ansi` — With ANSI escape codes

View ANSI snapshots: `cat test/snapshots/*.ansi`

### Determinism

Snapshots must be reproducible. Avoid:
- Random data (use fixed seed)
- Current timestamps (stub `Time.now`)

```ruby
def setup
  @fixed_time = Time.new(2025, 1, 1, 12, 0, 0)
  Time.stub(:now, @fixed_time) do
    yield
  end
end
```

---

## Isolated View Testing

Test views without the full terminal engine.

```ruby
def test_logs_view
  frame = RatatuiRuby::TestHelper::TestDoubles::MockFrame.new
  area = RatatuiRuby::TestHelper::TestDoubles::StubRect.new(width: 40, height: 10)

  MyView.new.render(frame, area)

  rendered = frame.rendered_widgets.first
  assert_equal "Logs", rendered[:widget].block.title
end
```

---

## Debugging Tests

### Debug Mode

Auto-enabled when including `TestHelper`. Provides better backtraces.

```ruby
# Or enable manually
RatatuiRuby.debug_mode!
```

### File Logging

Write debug output to a file instead of corrupting the display.

```ruby
DEBUG_LOG = File.open("debug.log", "a")

def debug(msg)
  DEBUG_LOG.puts("[#{Time.now}] #{msg}")
  DEBUG_LOG.flush
end
```

Tail in another terminal: `tail -f debug.log`

### Interactive Debugger

Standard debuggers conflict with raw mode. Options:

```ruby
# Option 1: Exit TUI temporarily
RatatuiRuby.restore_terminal
binding.pry
RatatuiRuby.init_terminal

# Option 2: Debug in test mode (no conflict)
with_test_terminal do
  binding.pry
  MyApp.new.render
end

# Option 3: Remote debugging
# Terminal 1: ruby my_app.rb (calls RatatuiRuby.debug_mode!)
# Terminal 2: rdbg --attach
```

---

## Testing Custom Widgets

Custom widgets return draw command arrays. Test directly.

```ruby
def test_hello_widget
  area = Rect.new(x: 0, y: 0, width: 20, height: 5)
  widget = HelloWidget.new
  commands = widget.render(area)

  assert_equal 1, commands.length
  assert_equal "Hello, World!", commands[0].string
end
```

Or use the test terminal for visual verification:

```ruby
def test_renders_correctly
  with_test_terminal(10, 5) do
    RatatuiRuby.draw(MyWidget.new)
    assert_equal "Expected  ", buffer_content[0]
  end
end
```

---

## Error Classes

Catch specific exceptions:

```ruby
begin
  RatatuiRuby.run { |tui| ... }
rescue RatatuiRuby::Error::Terminal => e
  # I/O failure (backend crashed)
rescue RatatuiRuby::Error::Safety => e
  # Lifetime violation (using Frame after block exits)
rescue RatatuiRuby::Error::Invariant => e
  # Contract violation (double init)
end
```
