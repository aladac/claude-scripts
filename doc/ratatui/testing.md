# Ratatui Testing

Test TUI applications without a real terminal using `TestBackend`.

## Setup

```rust
use ratatui::{
    backend::TestBackend,
    Terminal,
    widgets::{Paragraph, Block},
};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rendering() {
        // Create test terminal (80x24)
        let backend = TestBackend::new(80, 24);
        let mut terminal = Terminal::new(backend).unwrap();

        terminal.draw(|frame| {
            frame.render_widget(
                Paragraph::new("Hello World"),
                frame.area(),
            );
        }).unwrap();

        // Inspect buffer
        let buffer = terminal.backend().buffer();
        assert!(buffer_contains(buffer, "Hello World"));
    }
}
```

---

## TestBackend

Create a terminal with no actual display.

```rust
// Default: 80x24
let backend = TestBackend::new(80, 24);

// Custom size
let backend = TestBackend::new(40, 10);

// Create terminal
let mut terminal = Terminal::new(backend).unwrap();
```

---

## Buffer Inspection

### Raw Buffer Access

```rust
let buffer = terminal.backend().buffer();

// Get cell at position
let cell = buffer.get(0, 0);
cell.symbol();  // Character as &str
cell.fg;        // Foreground color
cell.bg;        // Background color
cell.modifier;  // Modifiers (bold, italic, etc.)
```

### Helper Functions

```rust
fn buffer_contains(buffer: &Buffer, text: &str) -> bool {
    let content: String = buffer
        .content()
        .iter()
        .map(|cell| cell.symbol())
        .collect();
    content.contains(text)
}

fn buffer_line(buffer: &Buffer, y: u16) -> String {
    (0..buffer.area.width)
        .map(|x| buffer.get(x, y).symbol())
        .collect()
}

fn assert_buffer_eq(buffer: &Buffer, expected: Vec<&str>) {
    for (y, line) in expected.iter().enumerate() {
        let actual = buffer_line(buffer, y as u16);
        assert_eq!(actual.trim_end(), *line, "Line {}", y);
    }
}
```

### Example

```rust
#[test]
fn test_list_rendering() {
    let backend = TestBackend::new(20, 5);
    let mut terminal = Terminal::new(backend).unwrap();

    terminal.draw(|frame| {
        let items = vec!["Item 1", "Item 2", "Item 3"];
        let list = List::new(items);
        frame.render_widget(list, frame.area());
    }).unwrap();

    let buffer = terminal.backend().buffer();
    assert!(buffer_contains(buffer, "Item 1"));
    assert!(buffer_contains(buffer, "Item 2"));
    assert!(buffer_contains(buffer, "Item 3"));
}
```

---

## Style Assertions

```rust
fn assert_style_at(buffer: &Buffer, x: u16, y: u16, expected: Style) {
    let cell = buffer.get(x, y);
    assert_eq!(cell.fg, expected.fg.unwrap_or(Color::Reset));
    assert_eq!(cell.bg, expected.bg.unwrap_or(Color::Reset));
}

#[test]
fn test_styled_text() {
    let backend = TestBackend::new(20, 5);
    let mut terminal = Terminal::new(backend).unwrap();

    terminal.draw(|frame| {
        frame.render_widget(
            Paragraph::new("Error").style(Style::new().fg(Color::Red)),
            frame.area(),
        );
    }).unwrap();

    let cell = terminal.backend().buffer().get(0, 0);
    assert_eq!(cell.fg, Color::Red);
}
```

---

## Snapshot Testing

Compare buffer against expected output.

```rust
#[test]
fn test_dashboard_snapshot() {
    let backend = TestBackend::new(40, 10);
    let mut terminal = Terminal::new(backend).unwrap();

    terminal.draw(|frame| {
        render_dashboard(frame);
    }).unwrap();

    let expected = vec![
        "┌──────────────────────────────────────┐",
        "│            Dashboard                 │",
        "├──────────────────────────────────────┤",
        "│ Status: OK                           │",
        "│ Items: 42                            │",
        "│                                      │",
        "│                                      │",
        "│                                      │",
        "│                                      │",
        "└──────────────────────────────────────┘",
    ];

    assert_buffer_eq(terminal.backend().buffer(), expected);
}
```

### Using insta for Snapshots

```toml
[dev-dependencies]
insta = "1.34"
```

```rust
use insta::assert_snapshot;

#[test]
fn test_ui_snapshot() {
    let backend = TestBackend::new(80, 24);
    let mut terminal = Terminal::new(backend).unwrap();

    terminal.draw(|frame| render_ui(frame)).unwrap();

    let content = buffer_to_string(terminal.backend().buffer());
    assert_snapshot!(content);
}

fn buffer_to_string(buffer: &Buffer) -> String {
    let mut output = String::new();
    for y in 0..buffer.area.height {
        for x in 0..buffer.area.width {
            output.push_str(buffer.get(x, y).symbol());
        }
        output.push('\n');
    }
    output
}
```

---

## Testing App State

```rust
struct App {
    items: Vec<String>,
    selected: usize,
}

impl App {
    fn next(&mut self) {
        if self.selected < self.items.len() - 1 {
            self.selected += 1;
        }
    }

    fn previous(&mut self) {
        if self.selected > 0 {
            self.selected -= 1;
        }
    }
}

#[test]
fn test_navigation() {
    let mut app = App {
        items: vec!["A".into(), "B".into(), "C".into()],
        selected: 0,
    };

    assert_eq!(app.selected, 0);

    app.next();
    assert_eq!(app.selected, 1);

    app.next();
    assert_eq!(app.selected, 2);

    app.next();  // Should not go past last
    assert_eq!(app.selected, 2);

    app.previous();
    assert_eq!(app.selected, 1);
}
```

---

## Testing Event Handling

```rust
use crossterm::event::{Event, KeyCode, KeyEvent, KeyModifiers};

impl App {
    fn handle_key(&mut self, key: KeyEvent) -> bool {
        match key.code {
            KeyCode::Char('q') => return false,  // Quit
            KeyCode::Down | KeyCode::Char('j') => self.next(),
            KeyCode::Up | KeyCode::Char('k') => self.previous(),
            _ => {}
        }
        true  // Continue
    }
}

#[test]
fn test_quit_on_q() {
    let mut app = App::default();
    let key = KeyEvent::new(KeyCode::Char('q'), KeyModifiers::empty());
    assert!(!app.handle_key(key));
}

#[test]
fn test_navigation_keys() {
    let mut app = App {
        items: vec!["A".into(), "B".into()],
        selected: 0,
    };

    let down = KeyEvent::new(KeyCode::Down, KeyModifiers::empty());
    app.handle_key(down);
    assert_eq!(app.selected, 1);

    let up = KeyEvent::new(KeyCode::Up, KeyModifiers::empty());
    app.handle_key(up);
    assert_eq!(app.selected, 0);
}
```

---

## Integration Testing

Test full render + input cycle.

```rust
#[test]
fn test_full_interaction() {
    let backend = TestBackend::new(40, 10);
    let mut terminal = Terminal::new(backend).unwrap();
    let mut app = App::new();

    // Initial render
    terminal.draw(|f| app.render(f)).unwrap();
    assert!(buffer_contains(terminal.backend().buffer(), "Item 1"));

    // Simulate key press
    app.handle_key(KeyEvent::new(KeyCode::Down, KeyModifiers::empty()));

    // Re-render
    terminal.draw(|f| app.render(f)).unwrap();

    // Verify selection changed
    let buffer = terminal.backend().buffer();
    // Check highlight moved to second item
}
```

---

## Debugging Tests

### Print Buffer

```rust
fn print_buffer(buffer: &Buffer) {
    for y in 0..buffer.area.height {
        let line: String = (0..buffer.area.width)
            .map(|x| buffer.get(x, y).symbol())
            .collect();
        println!("{:2}: |{}|", y, line);
    }
}

#[test]
fn debug_rendering() {
    // ... setup ...
    terminal.draw(|f| render(f)).unwrap();
    print_buffer(terminal.backend().buffer());
    // View output with: cargo test -- --nocapture
}
```

### Colored Output

```rust
fn print_buffer_colored(buffer: &Buffer) {
    for y in 0..buffer.area.height {
        for x in 0..buffer.area.width {
            let cell = buffer.get(x, y);
            // Use ANSI escape codes based on cell.fg/bg
            print!("{}", cell.symbol());
        }
        println!();
    }
}
```
