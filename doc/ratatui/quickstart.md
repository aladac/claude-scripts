# RatatuiRuby Quickstart

Ruby wrapper for [Ratatui](https://ratatui.rs) — build Terminal UIs with native Rust performance.

## Installation

```ruby
gem "ratatui_ruby"
```

## Basic Usage

```ruby
require "ratatui_ruby"

RatatuiRuby.run do |tui|
  loop do
    tui.draw do |frame|
      frame.render_widget(
        tui.paragraph(
          text: "Hello, Ratatui! Press 'q' to quit.",
          alignment: :center,
          block: tui.block(title: "My App", borders: [:all])
        ),
        frame.area
      )
    end

    case tui.poll_event
    in { type: :key, code: "q" } | { type: :key, code: "c", modifiers: ["ctrl"] }
      break
    else
      nil
    end
  end
end
```

## Core Concepts

### Immediate Mode

RatatuiRuby uses immediate mode rendering:
- You describe UI as data objects every frame
- No retained widget tree — rebuild on every draw
- State is external (your instance variables)

### Lifecycle

```ruby
# Automatic (recommended)
RatatuiRuby.run do |tui|
  # Terminal initialized, raw mode enabled
  # ...your app loop...
end
# Terminal automatically restored

# Manual (when needed)
RatatuiRuby.init_terminal
begin
  RatatuiRuby.draw { |frame| ... }
ensure
  RatatuiRuby.restore_terminal
end
```

### Viewport Modes

```ruby
# Fullscreen (default) - uses alternate screen, clears on exit
RatatuiRuby.run { |tui| ... }

# Inline - fixed height, preserves scrollback
RatatuiRuby.run(viewport: :inline, height: 10) { |tui| ... }
```

Inline is ideal for CLI tools that show progress/status without taking over the terminal.

## TUI Factory Methods

The `tui` object provides shorthand for all widgets:

```ruby
RatatuiRuby.run do |tui|
  tui.draw do |frame|
    # Layout
    areas = tui.layout_split(frame.area, direction: :horizontal, constraints: [
      tui.constraint_length(20),
      tui.constraint_fill(1)
    ])

    # Widgets
    frame.render_widget(tui.paragraph(text: "Sidebar"), areas[0])
    frame.render_widget(tui.list(items: %w[A B C]), areas[1])
  end
end
```

## Raw API

For custom abstractions, use explicit classes:

```ruby
RatatuiRuby::Widgets::Paragraph.new(text: "Hello")
RatatuiRuby::Layout::Constraint.length(10)
RatatuiRuby::Style::Style.new(fg: :red, modifiers: [:bold])
```

## Signal Handling

- `Ctrl+C` in raw mode is captured as a key event (not SIGINT)
- Handle it in your event loop: `break if event == :ctrl_c`
- External SIGTERM/SIGINT properly restore terminal via `ensure`

## Reference

- [Widgets](./widgets.md) - All available widgets
- [Layout](./layout.md) - Constraint-based layouts
- [State](./state.md) - Stateful widgets (List, Table)
- [Events](./events.md) - Keyboard, mouse, resize
- [Testing](./testing.md) - Test helpers and snapshots
- [Custom Widgets](./custom-widgets.md) - Build your own
