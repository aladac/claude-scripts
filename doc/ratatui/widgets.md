# Ratatui Widgets

All widgets implement the `Widget` trait. Create them with builder patterns.

## Widget Categories

| Category | Widgets |
|----------|---------|
| **Text** | Paragraph, Line, Span, Text |
| **Data** | List, Table, Sparkline, BarChart, Chart, Calendar |
| **Layout** | Block, Tabs, Scrollbar, Clear |
| **Progress** | Gauge, LineGauge |
| **Canvas** | Canvas (shapes, custom drawing) |

---

## Paragraph

Display text with alignment, wrapping, and scrolling.

```rust
use ratatui::widgets::{Paragraph, Block, Wrap};
use ratatui::style::{Style, Color};
use ratatui::layout::Alignment;

Paragraph::new("Hello, World!")
    .style(Style::new().fg(Color::Green))
    .alignment(Alignment::Center)
    .wrap(Wrap { trim: true })
    .scroll((0, 0))  // (y, x) offset
    .block(Block::bordered().title("Output"))
```

### Rich Text

```rust
use ratatui::text::{Line, Span};

let line = Line::from(vec![
    Span::styled("Error: ", Style::new().fg(Color::Red).bold()),
    Span::raw("File not found"),
]);
Paragraph::new(line)
```

### Multi-line

```rust
use ratatui::text::Text;

let text = Text::from(vec![
    Line::from("Line 1"),
    Line::from("Line 2"),
    Line::styled("Line 3", Style::new().italic()),
]);
Paragraph::new(text)
```

---

## List

Selectable list with navigation and scrolling.

```rust
use ratatui::widgets::{List, ListItem, ListState, Block};
use ratatui::style::{Style, Modifier};

let items = vec![
    ListItem::new("Item 1"),
    ListItem::new("Item 2"),
    ListItem::new("Item 3"),
];

let list = List::new(items)
    .highlight_style(Style::new().add_modifier(Modifier::REVERSED))
    .highlight_symbol(">> ")
    .highlight_spacing(HighlightSpacing::Always)
    .direction(ListDirection::TopToBottom)
    .block(Block::bordered().title("Menu"));

// Render with state
let mut state = ListState::default().with_selected(Some(0));
frame.render_stateful_widget(list, area, &mut state);

// Navigation
state.select_next();
state.select_previous();
state.select_first();
state.select_last();
```

### Styled Items

```rust
let items = vec![
    ListItem::new("Active").style(Style::new().fg(Color::Green)),
    ListItem::new("Pending").style(Style::new().fg(Color::Yellow)),
    ListItem::new("Error").style(Style::new().fg(Color::Red)),
];
```

---

## Table

Structured data in rows and columns.

```rust
use ratatui::widgets::{Table, Row, Cell, TableState, Block};
use ratatui::layout::Constraint;

let header = Row::new(vec!["Name", "Status", "Port"])
    .style(Style::new().bold())
    .bottom_margin(1);

let rows = vec![
    Row::new(vec!["api", "running", "8080"]),
    Row::new(vec!["worker", "stopped", "-"]),
];

let widths = [
    Constraint::Percentage(40),
    Constraint::Percentage(30),
    Constraint::Percentage(30),
];

let table = Table::new(rows, widths)
    .header(header)
    .row_highlight_style(Style::new().reversed())
    .highlight_symbol("> ")
    .column_spacing(1)
    .block(Block::bordered().title("Services"));

// Render with state
let mut state = TableState::default().with_selected(Some(0));
frame.render_stateful_widget(table, area, &mut state);
```

### Styled Cells

```rust
let row = Row::new(vec![
    Cell::from("api"),
    Cell::from("running").style(Style::new().fg(Color::Green)),
    Cell::from("8080"),
]);
```

---

## Block

Container with borders and title.

```rust
use ratatui::widgets::{Block, Borders, BorderType};

Block::new()
    .title("Dashboard")
    .borders(Borders::ALL)
    .border_style(Style::new().fg(Color::Cyan))
    .border_type(BorderType::Rounded)
    .title_alignment(Alignment::Center)

// Shorthand
Block::bordered().title("Title")
```

### Border Types

```rust
BorderType::Plain    // ─│┌┐└┘
BorderType::Rounded  // ─│╭╮╰╯
BorderType::Double   // ═║╔╗╚╝
BorderType::Thick    // ━┃┏┓┗┛
```

---

## Gauge

Progress indicator.

```rust
use ratatui::widgets::{Gauge, Block};

Gauge::default()
    .ratio(0.75)  // 0.0 to 1.0
    .label("75%")
    .gauge_style(Style::new().fg(Color::Green))
    .block(Block::bordered().title("Progress"))
```

---

## LineGauge

Horizontal line progress.

```rust
use ratatui::widgets::LineGauge;
use ratatui::symbols::line;

LineGauge::default()
    .ratio(0.5)
    .label("Loading...")
    .line_set(line::THICK)
    .filled_style(Style::new().fg(Color::Blue))
    .unfilled_style(Style::new().fg(Color::DarkGray))
```

---

## Sparkline

Mini chart for data series.

```rust
use ratatui::widgets::{Sparkline, Block};

Sparkline::default()
    .data(&[1, 4, 2, 8, 5, 7, 3])
    .style(Style::new().fg(Color::Cyan))
    .direction(RenderDirection::LeftToRight)
    .block(Block::bordered())
```

---

## BarChart

Vertical/horizontal bar chart.

```rust
use ratatui::widgets::{BarChart, Bar, BarGroup, Block};

let data = BarGroup::default().bars(&[
    Bar::default().value(10).label("Mon".into()),
    Bar::default().value(20).label("Tue".into()),
    Bar::default().value(15).label("Wed".into()),
]);

BarChart::default()
    .data(data)
    .bar_width(5)
    .bar_gap(1)
    .bar_style(Style::new().fg(Color::Blue))
    .value_style(Style::new().fg(Color::White))
    .label_style(Style::new().fg(Color::Cyan))
    .direction(Direction::Vertical)
```

---

## Tabs

Tab bar.

```rust
use ratatui::widgets::{Tabs, Block};

Tabs::new(vec!["Home", "Settings", "Help"])
    .select(0)
    .style(Style::new().fg(Color::White))
    .highlight_style(Style::new().fg(Color::Yellow).bold())
    .divider(" | ")
    .block(Block::default().borders(Borders::BOTTOM))
```

---

## Scrollbar

Scroll indicator.

```rust
use ratatui::widgets::{Scrollbar, ScrollbarOrientation, ScrollbarState};

let scrollbar = Scrollbar::new(ScrollbarOrientation::VerticalRight)
    .thumb_style(Style::new().fg(Color::Cyan))
    .track_style(Style::new().fg(Color::DarkGray))
    .begin_symbol(Some("▲"))
    .end_symbol(Some("▼"));

let mut state = ScrollbarState::new(100).position(25);
frame.render_stateful_widget(scrollbar, area, &mut state);
```

---

## Canvas

Low-level drawing surface for shapes.

```rust
use ratatui::widgets::canvas::{Canvas, Line, Circle, Rectangle};

Canvas::default()
    .x_bounds([0.0, 100.0])
    .y_bounds([0.0, 100.0])
    .marker(Marker::Braille)
    .paint(|ctx| {
        ctx.draw(&Line {
            x1: 0.0, y1: 0.0,
            x2: 100.0, y2: 100.0,
            color: Color::Red,
        });
        ctx.draw(&Circle {
            x: 50.0, y: 50.0,
            radius: 20.0,
            color: Color::Blue,
        });
    })
```

### Markers

```rust
Marker::Dot       // ·
Marker::Block     // █
Marker::Bar       // ▄
Marker::Braille   // ⠿ (high resolution)
Marker::HalfBlock // ▀▄
```

---

## Clear

Clear area (fill with spaces).

```rust
use ratatui::widgets::Clear;

frame.render_widget(Clear, popup_area);
frame.render_widget(popup_widget, popup_area);
```

---

## Style Reference

```rust
use ratatui::style::{Color, Modifier, Style, Stylize};

// Builder pattern
Style::new()
    .fg(Color::Red)
    .bg(Color::Black)
    .add_modifier(Modifier::BOLD | Modifier::ITALIC);

// Stylize trait (fluent)
"text".red().bold().on_black()

// Named colors
Color::Black, Color::Red, Color::Green, Color::Yellow,
Color::Blue, Color::Magenta, Color::Cyan, Color::Gray, Color::White,
Color::DarkGray, Color::LightRed, Color::LightGreen, Color::LightYellow,
Color::LightBlue, Color::LightMagenta, Color::LightCyan

// RGB
Color::Rgb(255, 100, 0)

// 256-color palette
Color::Indexed(42)

// Reset
Color::Reset
```

### Modifiers

```rust
Modifier::BOLD
Modifier::DIM
Modifier::ITALIC
Modifier::UNDERLINED
Modifier::SLOW_BLINK
Modifier::RAPID_BLINK
Modifier::REVERSED
Modifier::HIDDEN
Modifier::CROSSED_OUT
```
