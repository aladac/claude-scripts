# Ratatui State Management

## Stateless vs Stateful Widgets

Most widgets are **stateless** — you render them with explicit properties each frame:

```rust
// Stateless: selection passed directly
let list = List::new(items);
frame.render_widget(list, area);
```

Some widgets support **stateful rendering** — a mutable State object tracks selection/scroll:

```rust
// Stateful: selection tracked in state
let mut state = ListState::default().with_selected(Some(0));
frame.render_stateful_widget(list, area, &mut state);
```

---

## When to Use Stateful Rendering

Use `render_stateful_widget` when you need to:

1. **Track selection** across frames
2. **Auto-scroll to selection** without manual offset math
3. **Use navigation helpers** like `select_next()`, `select_previous()`
4. **Read back scroll offset** calculated by Ratatui

---

## ListState

Mutable state for List widgets.

```rust
use ratatui::widgets::ListState;

let mut state = ListState::default();

// Selection
state.select(Some(0));           // Select first item
state.select(None);              // Deselect
state.selected();                // => Option<usize>

// Navigation
state.select_next();             // Move down
state.select_previous();         // Move up
state.select_first();            // Jump to first
state.select_last();             // Jump to last

// Scroll offset (read after render)
state.offset();                  // Current scroll position
*state.offset_mut() = 10;        // Set scroll offset
```

### With Builder

```rust
let state = ListState::default()
    .with_selected(Some(0))
    .with_offset(0);
```

### Usage

```rust
struct App {
    items: Vec<String>,
    list_state: ListState,
}

impl App {
    fn new() -> Self {
        Self {
            items: vec!["Item 1".into(), "Item 2".into()],
            list_state: ListState::default().with_selected(Some(0)),
        }
    }

    fn render(&mut self, frame: &mut Frame) {
        let list = List::new(self.items.iter().map(|i| i.as_str()))
            .highlight_style(Style::new().reversed())
            .highlight_symbol(">> ")
            .block(Block::bordered().title("Select"));

        frame.render_stateful_widget(list, frame.area(), &mut self.list_state);
    }

    fn handle_key(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Down | KeyCode::Char('j') => self.list_state.select_next(),
            KeyCode::Up | KeyCode::Char('k') => self.list_state.select_previous(),
            KeyCode::Home => self.list_state.select_first(),
            KeyCode::End => self.list_state.select_last(),
            _ => {}
        }
    }
}
```

---

## TableState

Mutable state for Table widgets.

```rust
use ratatui::widgets::TableState;

let mut state = TableState::default();

// Row selection
state.select(Some(0));
state.selected();                // => Option<usize>
state.select_next();
state.select_previous();
state.select_first();
state.select_last();

// Scroll offset
state.offset();
*state.offset_mut() = 5;
```

### Usage

```rust
let table = Table::new(rows, widths)
    .header(header)
    .row_highlight_style(Style::new().reversed())
    .highlight_symbol("> ");

frame.render_stateful_widget(table, area, &mut self.table_state);
```

---

## ScrollbarState

State for Scrollbar widgets.

```rust
use ratatui::widgets::ScrollbarState;

let mut state = ScrollbarState::new(100)  // content_length
    .position(25)
    .viewport_content_length(20);

// Navigation
state.prev();
state.next();
state.first();
state.last();

// Position
state.position();
state.scroll_up(5);
state.scroll_down(5);
```

### Syncing with List

```rust
fn render(&mut self, frame: &mut Frame, area: Rect) {
    // Render list
    let list = List::new(self.items.iter().map(|i| i.as_str()));
    frame.render_stateful_widget(list, area, &mut self.list_state);

    // Sync scrollbar with list
    let scrollbar = Scrollbar::new(ScrollbarOrientation::VerticalRight);
    let mut scrollbar_state = ScrollbarState::new(self.items.len())
        .position(self.list_state.offset());

    frame.render_stateful_widget(
        scrollbar,
        area.inner(Margin { vertical: 1, horizontal: 0 }),
        &mut scrollbar_state,
    );
}
```

---

## App State Pattern

Keep application data separate from widget state:

```rust
struct App {
    // Application data
    items: Vec<Item>,
    filter: String,

    // Widget state
    list_state: ListState,
    scroll_state: ScrollbarState,
}

impl App {
    fn filtered_items(&self) -> Vec<&Item> {
        self.items
            .iter()
            .filter(|i| i.name.contains(&self.filter))
            .collect()
    }

    fn set_filter(&mut self, filter: String) {
        self.filter = filter;
        // Reset selection when filter changes
        self.list_state.select_first();
    }

    fn selected_item(&self) -> Option<&Item> {
        self.list_state.selected()
            .and_then(|i| self.filtered_items().get(i))
            .copied()
    }
}
```

---

## Bounds Checking

Navigation methods handle bounds automatically:

```rust
// select_next() won't go past last item
// select_previous() won't go before first item
self.list_state.select_next();
```

For manual bounds checking:

```rust
fn next(&mut self) {
    let i = match self.list_state.selected() {
        Some(i) if i < self.items.len() - 1 => i + 1,
        _ => 0,
    };
    self.list_state.select(Some(i));
}

fn previous(&mut self) {
    let i = match self.list_state.selected() {
        Some(0) | None => self.items.len() - 1,
        Some(i) => i - 1,
    };
    self.list_state.select(Some(i));
}
```

---

## Multiple Stateful Widgets

```rust
struct App {
    active_pane: Pane,
    file_list_state: ListState,
    preview_scroll: u16,
    tab_state: usize,
}

enum Pane {
    FileList,
    Preview,
}

impl App {
    fn handle_key(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Tab => self.toggle_pane(),
            KeyCode::Down => match self.active_pane {
                Pane::FileList => self.file_list_state.select_next(),
                Pane::Preview => self.preview_scroll += 1,
            },
            _ => {}
        }
    }
}
```
