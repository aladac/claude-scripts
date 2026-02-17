# Ratatui Layout

Constraint-based layouts that adapt to terminal size.

## Layout::vertical / Layout::horizontal

Split an area into regions using constraints.

```rust
use ratatui::layout::{Layout, Constraint, Direction, Rect};

let [header, content, footer] = Layout::vertical([
    Constraint::Length(3),    // Fixed 3 rows
    Constraint::Fill(1),      // Remaining space
    Constraint::Length(1),    // Fixed 1 row
]).areas(frame.area());

// Or with direction
let areas = Layout::default()
    .direction(Direction::Horizontal)
    .constraints([
        Constraint::Length(20),
        Constraint::Fill(1),
    ])
    .split(frame.area());
```

---

## Constraints

### Length

Fixed size in cells.

```rust
Constraint::Length(10)   // Exactly 10 cells
```

### Percentage

Percentage of available space.

```rust
Constraint::Percentage(50)   // 50% of area
```

### Min / Max

Minimum or maximum size.

```rust
Constraint::Min(5)     // At least 5 cells, grows if space permits
Constraint::Max(20)    // At most 20 cells, shrinks if needed
```

### Fill

Proportional distribution of remaining space (like flex-grow).

```rust
Constraint::Fill(1)    // Equal share
Constraint::Fill(2)    // Double share

// Example: sidebar (1x) + content (2x)
let [sidebar, content] = Layout::horizontal([
    Constraint::Fill(1),
    Constraint::Fill(2),
]).areas(area);
```

### Ratio

Exact fraction of space.

```rust
Constraint::Ratio(1, 3)   // 1/3rd of area
Constraint::Ratio(2, 5)   // 2/5ths
```

---

## Rect

Rectangle with position and size.

```rust
let rect = Rect::new(0, 0, 80, 24);

rect.x           // Left edge
rect.y           // Top edge
rect.width       // Width in cells
rect.height      // Height in cells
rect.right()     // x + width
rect.bottom()    // y + height
rect.area()      // width * height
rect.is_empty()  // width or height is 0
```

### Frame Area

```rust
terminal.draw(|frame| {
    let area = frame.area();  // Full terminal area
})?;
```

### Inner Area (for borders)

```rust
let block = Block::bordered().title("Content");
let inner = block.inner(area);  // Area inside border
frame.render_widget(block, area);
frame.render_widget(content, inner);
```

---

## Nested Layouts

Compose layouts by splitting recursively.

```rust
// Main layout: sidebar + content
let [sidebar_area, main_area] = Layout::horizontal([
    Constraint::Length(25),
    Constraint::Fill(1),
]).areas(frame.area());

// Split content: header + body + footer
let [header, body, footer] = Layout::vertical([
    Constraint::Length(3),
    Constraint::Fill(1),
    Constraint::Length(1),
]).areas(main_area);
```

---

## Common Patterns

### Three-Pane Layout

```
+----------+-------------------+
|          |      Header       |
| Sidebar  +-------------------+
|          |      Content      |
|          +-------------------+
|          |      Footer       |
+----------+-------------------+
```

```rust
let [sidebar, main] = Layout::horizontal([
    Constraint::Length(20),
    Constraint::Fill(1),
]).areas(frame.area());

let [header, content, footer] = Layout::vertical([
    Constraint::Length(3),
    Constraint::Fill(1),
    Constraint::Length(1),
]).areas(main);
```

### Equal Columns

```rust
let [left, center, right] = Layout::horizontal([
    Constraint::Percentage(33),
    Constraint::Percentage(34),
    Constraint::Percentage(33),
]).areas(area);
```

### Responsive (Min + Fill)

```rust
// Sidebar shrinks below content
let [sidebar, content] = Layout::horizontal([
    Constraint::Min(15),     // Sidebar at least 15
    Constraint::Fill(1),     // Content takes rest
]).areas(area);
```

### Centered Content

```rust
fn centered_rect(percent_x: u16, percent_y: u16, area: Rect) -> Rect {
    let [_, center, _] = Layout::vertical([
        Constraint::Percentage((100 - percent_y) / 2),
        Constraint::Percentage(percent_y),
        Constraint::Percentage((100 - percent_y) / 2),
    ]).areas(area);

    let [_, center, _] = Layout::horizontal([
        Constraint::Percentage((100 - percent_x) / 2),
        Constraint::Percentage(percent_x),
        Constraint::Percentage((100 - percent_x) / 2),
    ]).areas(center);

    center
}

// Use for popups
let popup_area = centered_rect(60, 20, frame.area());
frame.render_widget(Clear, popup_area);
frame.render_widget(popup, popup_area);
```

---

## Margin and Spacing

```rust
Layout::vertical([...])
    .margin(1)           // All sides
    .horizontal_margin(2)
    .vertical_margin(1)
    .spacing(1)          // Between areas
```
