# Ratatui Quickstart

[Ratatui](https://ratatui.rs) — build Terminal UIs in Rust with immediate-mode rendering.

## Installation

```toml
# Cargo.toml
[dependencies]
ratatui = "0.29"
crossterm = "0.28"
```

## Basic Usage

```rust
use ratatui::{
    crossterm::event::{self, Event, KeyCode},
    widgets::{Block, Paragraph},
    DefaultTerminal, Frame,
};

fn main() -> std::io::Result<()> {
    let mut terminal = ratatui::init();
    let result = run(&mut terminal);
    ratatui::restore();
    result
}

fn run(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    loop {
        terminal.draw(|frame| ui(frame))?;

        if let Event::Key(key) = event::read()? {
            if key.code == KeyCode::Char('q') {
                break Ok(());
            }
        }
    }
}

fn ui(frame: &mut Frame) {
    frame.render_widget(
        Paragraph::new("Hello, Ratatui! Press 'q' to quit.")
            .block(Block::bordered().title("My App")),
        frame.area(),
    );
}
```

## Core Concepts

### Immediate Mode

Ratatui uses immediate mode rendering:
- You describe UI as data every frame
- No retained widget tree — rebuild on every draw
- State is external (your App struct)

### Lifecycle

```rust
// Automatic (recommended) - ratatui 0.29+
fn main() -> std::io::Result<()> {
    let mut terminal = ratatui::init();
    let result = run(&mut terminal);
    ratatui::restore();
    result
}

// Manual (when needed)
use ratatui::crossterm::{
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};

fn setup_terminal() -> std::io::Result<Terminal<CrosstermBackend<Stdout>>> {
    enable_raw_mode()?;
    let mut stdout = std::io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    Terminal::new(CrosstermBackend::new(stdout))
}

fn restore_terminal() -> std::io::Result<()> {
    disable_raw_mode()?;
    execute!(std::io::stdout(), LeaveAlternateScreen)?;
    Ok(())
}
```

### App Pattern

```rust
struct App {
    running: bool,
    counter: i32,
}

impl App {
    fn new() -> Self {
        Self { running: true, counter: 0 }
    }

    fn run(&mut self, terminal: &mut DefaultTerminal) -> std::io::Result<()> {
        while self.running {
            terminal.draw(|frame| self.render(frame))?;
            self.handle_events()?;
        }
        Ok(())
    }

    fn render(&self, frame: &mut Frame) {
        let text = format!("Counter: {}", self.counter);
        frame.render_widget(
            Paragraph::new(text).block(Block::bordered()),
            frame.area(),
        );
    }

    fn handle_events(&mut self) -> std::io::Result<()> {
        if event::poll(std::time::Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Char('q') => self.running = false,
                    KeyCode::Up => self.counter += 1,
                    KeyCode::Down => self.counter -= 1,
                    _ => {}
                }
            }
        }
        Ok(())
    }
}

fn main() -> std::io::Result<()> {
    let mut terminal = ratatui::init();
    let result = App::new().run(&mut terminal);
    ratatui::restore();
    result
}
```

### Panic Handler

Restore terminal on panic:

```rust
use std::panic;

fn main() -> std::io::Result<()> {
    // Install panic hook to restore terminal
    let original_hook = panic::take_hook();
    panic::set_hook(Box::new(move |panic_info| {
        let _ = ratatui::restore();
        original_hook(panic_info);
    }));

    let mut terminal = ratatui::init();
    let result = run(&mut terminal);
    ratatui::restore();
    result
}
```

## Signal Handling

- `Ctrl+C` in raw mode is captured as a key event (not SIGINT)
- Handle it in your event loop:

```rust
match (key.modifiers, key.code) {
    (KeyModifiers::CONTROL, KeyCode::Char('c')) => self.running = false,
    _ => {}
}
```

## Reference

- [Widgets](./widgets.md) - All available widgets
- [Layout](./layout.md) - Constraint-based layouts
- [State](./state.md) - Stateful widgets (List, Table)
- [Events](./events.md) - Keyboard, mouse, resize
- [Testing](./testing.md) - TestBackend and assertions
- [Custom Widgets](./custom-widgets.md) - Build your own
- [Async](./async.md) - Tokio integration
