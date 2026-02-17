# RatatuiRuby Events

## Polling Events

```ruby
event = RatatuiRuby.poll_event

# Or via tui object
event = tui.poll_event
```

### Timeout Modes

```ruby
# Default: ~60 FPS (0.016s timeout)
event = poll_event

# Blocking: wait forever
event = poll_event(timeout: nil)

# Non-blocking: return immediately
event = poll_event(timeout: 0.0)

# Custom timeout (seconds)
event = poll_event(timeout: 0.5)
```

---

## Event Types

| Class | Discriminator | Attributes |
|-------|---------------|------------|
| `Event::Key` | `:key` | `code`, `modifiers` |
| `Event::Mouse` | `:mouse` | `kind`, `x`, `y`, `button`, `modifiers` |
| `Event::Resize` | `:resize` | `width`, `height` |
| `Event::Paste` | `:paste` | `content` |
| `Event::FocusGained` | `:focus_gained` | (none) |
| `Event::FocusLost` | `:focus_lost` | (none) |
| `Event::None` | `:none` | (none) |

---

## Handling Keys

### Simple Comparison

```ruby
if event == "q"
  break
end

if event == :enter
  submit_form
end

if event == :ctrl_c
  break
end
```

### Supported Symbols

```ruby
# Special keys
:enter, :esc, :tab, :backspace, :delete
:up, :down, :left, :right
:home, :end, :page_up, :page_down
:insert, :f1, :f2, ... :f12

# Modifier combos
:ctrl_c, :ctrl_s, :ctrl_z
:alt_enter, :shift_tab
```

### Predicate Methods

```ruby
if event.key?
  if event.ctrl? && event.code == "s"
    save_file
  end
end

event.text?     # Printable character?
event.ctrl?     # Ctrl held?
event.alt?      # Alt held?
event.shift?    # Shift held?
```

### Pattern Matching

```ruby
case poll_event
in type: :key, code: "q"
  break

in type: :key, code: "c", modifiers: ["ctrl"]
  break

in type: :key, code: "up" | "k"
  move_up

in type: :key, code: "down" | "j"
  move_down

in type: :key, code: /^[a-z]$/ => char
  handle_char(char)

in type: :none
  # No event, continue loop
end
```

---

## Handling Mouse

```ruby
case poll_event
in type: :mouse, kind: "down", x:, y:, button: "left"
  handle_click(x, y)

in type: :mouse, kind: "drag", x:, y:
  handle_drag(x, y)

in type: :mouse, kind: "scroll_up"
  scroll_up

in type: :mouse, kind: "scroll_down"
  scroll_down
end
```

### Mouse Predicates

```ruby
if event.mouse?
  event.down?         # Button pressed
  event.up?           # Button released
  event.drag?         # Dragging
  event.scroll_up?
  event.scroll_down?
  event.x             # Column
  event.y             # Row
  event.button        # "left", "right", "middle"
end
```

---

## Handling Resize

```ruby
in type: :resize, width:, height:
  @terminal_size = [width, height]
  redraw_layout
```

---

## Handling Paste

```ruby
in type: :paste, content:
  @input_buffer += content
```

---

## Polymorphic Predicates

Safe to call on any event:

```ruby
event.key?           # Is this a key event?
event.mouse?         # Is this a mouse event?
event.resize?        # Is this a resize event?
event.paste?         # Is this a paste event?
event.focus_gained?
event.focus_lost?
event.none?          # No event (timeout)
```

---

## Event Loop Patterns

### Basic Loop

```ruby
loop do
  tui.draw { |frame| render(frame) }

  case tui.poll_event
  in { type: :key, code: "q" }
    break
  in { type: :key, code: "up" }
    @cursor -= 1
  in { type: :key, code: "down" }
    @cursor += 1
  else
    nil
  end
end
```

### Blocking (Low CPU)

```ruby
loop do
  tui.draw { |frame| render(frame) }

  # Wait indefinitely for input (0% CPU when idle)
  event = tui.poll_event(timeout: nil)

  break if event == "q"
  handle_event(event)
end
```

### With Animations

```ruby
loop do
  @frame_count += 1
  tui.draw { |frame| render_with_animation(frame) }

  # Short timeout for smooth animation
  case tui.poll_event(timeout: 0.033)  # ~30 FPS
  in { type: :key, code: "q" }
    break
  else
    nil
  end
end
```

---

## macOS Notes

- **Option key** maps to `alt`
- **Command key** is usually intercepted by terminal emulator
- Some terminals map Command to Meta/Alt — check your terminal settings
