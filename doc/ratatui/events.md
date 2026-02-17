# Ratatui Events

Event handling with crossterm.

## Reading Events

```rust
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use std::time::Duration;

// Blocking read
if let Event::Key(key) = event::read()? {
    // Handle key
}

// Non-blocking with poll
if event::poll(Duration::from_millis(100))? {
    match event::read()? {
        Event::Key(key) => handle_key(key),
        Event::Mouse(mouse) => handle_mouse(mouse),
        Event::Resize(w, h) => handle_resize(w, h),
        _ => {}
    }
}
```

---

## Event Types

| Variant | Description |
|---------|-------------|
| `Event::Key(KeyEvent)` | Keyboard input |
| `Event::Mouse(MouseEvent)` | Mouse input |
| `Event::Resize(u16, u16)` | Terminal resized |
| `Event::Paste(String)` | Bracketed paste |
| `Event::FocusGained` | Terminal gained focus |
| `Event::FocusLost` | Terminal lost focus |

---

## Handling Keys

### KeyEvent Fields

```rust
pub struct KeyEvent {
    pub code: KeyCode,
    pub modifiers: KeyModifiers,
    pub kind: KeyEventKind,  // Press, Release, Repeat
    pub state: KeyEventState,
}
```

### KeyCode Variants

```rust
// Characters
KeyCode::Char('a')
KeyCode::Char('A')  // Shift+a

// Special keys
KeyCode::Enter
KeyCode::Esc
KeyCode::Tab
KeyCode::Backspace
KeyCode::Delete
KeyCode::Insert

// Navigation
KeyCode::Up
KeyCode::Down
KeyCode::Left
KeyCode::Right
KeyCode::Home
KeyCode::End
KeyCode::PageUp
KeyCode::PageDown

// Function keys
KeyCode::F(1)  // F1-F12
```

### Modifiers

```rust
KeyModifiers::CONTROL
KeyModifiers::SHIFT
KeyModifiers::ALT
KeyModifiers::SUPER  // Cmd on macOS
KeyModifiers::HYPER
KeyModifiers::META
KeyModifiers::NONE

// Check modifiers
if key.modifiers.contains(KeyModifiers::CONTROL) {
    // Ctrl held
}
```

### Pattern Matching

```rust
match event::read()? {
    Event::Key(KeyEvent { code, modifiers, .. }) => {
        match (modifiers, code) {
            // Quit
            (_, KeyCode::Char('q')) => return Ok(()),
            (KeyModifiers::CONTROL, KeyCode::Char('c')) => return Ok(()),

            // Navigation
            (_, KeyCode::Up | KeyCode::Char('k')) => self.previous(),
            (_, KeyCode::Down | KeyCode::Char('j')) => self.next(),
            (_, KeyCode::Home | KeyCode::Char('g')) => self.first(),
            (_, KeyCode::End | KeyCode::Char('G')) => self.last(),

            // Page navigation
            (KeyModifiers::CONTROL, KeyCode::Char('u')) => self.page_up(),
            (KeyModifiers::CONTROL, KeyCode::Char('d')) => self.page_down(),

            // Select
            (_, KeyCode::Enter) => self.select(),

            // Search
            (_, KeyCode::Char('/')) => self.start_search(),

            // Text input
            (_, KeyCode::Char(c)) => self.input(c),
            (_, KeyCode::Backspace) => self.backspace(),

            _ => {}
        }
    }
    _ => {}
}
```

---

## Handling Mouse

Enable mouse capture:

```rust
use crossterm::event::{EnableMouseCapture, DisableMouseCapture};
use crossterm::execute;

// On init
execute!(stdout, EnableMouseCapture)?;

// On restore
execute!(stdout, DisableMouseCapture)?;
```

### MouseEvent

```rust
use crossterm::event::{MouseEvent, MouseEventKind, MouseButton};

match event::read()? {
    Event::Mouse(MouseEvent { kind, column, row, modifiers }) => {
        match kind {
            MouseEventKind::Down(MouseButton::Left) => {
                handle_click(column, row);
            }
            MouseEventKind::Down(MouseButton::Right) => {
                show_context_menu(column, row);
            }
            MouseEventKind::Drag(MouseButton::Left) => {
                handle_drag(column, row);
            }
            MouseEventKind::ScrollUp => scroll_up(),
            MouseEventKind::ScrollDown => scroll_down(),
            MouseEventKind::Moved => {
                // Mouse moved (if tracking enabled)
            }
            _ => {}
        }
    }
    _ => {}
}
```

### Click Detection

```rust
fn clicked_in_area(x: u16, y: u16, area: Rect) -> bool {
    area.contains(Position::new(x, y))
}

// In list
fn clicked_item(&self, y: u16, area: Rect) -> Option<usize> {
    if y < area.y || y >= area.y + area.height {
        return None;
    }
    let index = (y - area.y) as usize + self.scroll_offset;
    if index < self.items.len() {
        Some(index)
    } else {
        None
    }
}
```

---

## Handling Resize

```rust
Event::Resize(width, height) => {
    self.terminal_size = (width, height);
    // Layout will adapt on next draw
}
```

---

## Event Loop Patterns

### Basic Loop

```rust
fn run(&mut self, terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    while self.running {
        terminal.draw(|frame| self.render(frame))?;
        self.handle_events()?;
    }
    Ok(())
}

fn handle_events(&mut self) -> std::io::Result<()> {
    if event::poll(Duration::from_millis(100))? {
        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') => self.running = false,
                _ => {}
            }
        }
    }
    Ok(())
}
```

### Blocking (Low CPU)

```rust
// Block until event (0% CPU when idle)
match event::read()? {
    Event::Key(key) => handle_key(key),
    Event::Resize(_, _) => {} // Will redraw on next iteration
    _ => {}
}
```

### With Tick Rate (Animations)

```rust
use std::time::{Duration, Instant};

let tick_rate = Duration::from_millis(33);  // ~30 FPS
let mut last_tick = Instant::now();

loop {
    let timeout = tick_rate.saturating_sub(last_tick.elapsed());

    if event::poll(timeout)? {
        // Handle event
    }

    if last_tick.elapsed() >= tick_rate {
        self.tick();  // Update animations
        last_tick = Instant::now();
    }

    terminal.draw(|frame| self.render(frame))?;
}
```

---

## macOS Notes

- **Option key** maps to `ALT`
- **Command key** is usually intercepted by terminal emulator
- Some terminals map Command to Meta — check terminal settings
