# Ratatui Custom Widgets

Build custom widgets by implementing the `Widget` trait.

## Terminal Capabilities

Terminals have character cells, not pixels. Each cell holds:
- One Unicode grapheme
- Foreground color
- Background color
- Text modifiers (bold, italic, underline)

What you can draw:
- **Characters**: Any Unicode character
- **Box-drawing**: `│`, `┌`, `─`, `└`
- **Block elements**: `▀`, `▄`, `█`, `░`, `▒`, `▓`
- **Braille patterns**: 2×4 "pixel" grids per cell
- **Nerd Fonts**: Icons if user's font supports them

---

## The Widget Trait

```rust
pub trait Widget {
    fn render(self, area: Rect, buf: &mut Buffer);
}
```

Implement this for your custom widget:

```rust
use ratatui::{
    buffer::Buffer,
    layout::Rect,
    style::Style,
    widgets::Widget,
};

struct HelloWidget {
    style: Style,
}

impl Widget for HelloWidget {
    fn render(self, area: Rect, buf: &mut Buffer) {
        buf.set_string(area.x, area.y, "Hello, World!", self.style);
    }
}
```

---

## Buffer Methods

### Setting Content

```rust
// Set string at position
buf.set_string(x, y, "text", style);

// Set single character
buf.get_mut(x, y).set_char('X');

// Set character with style
buf.get_mut(x, y)
    .set_char('X')
    .set_style(Style::new().fg(Color::Red));

// Set styled spans
buf.set_line(x, y, &Line::from(vec![
    Span::styled("Error", Style::new().red()),
    Span::raw(": "),
    Span::raw("message"),
]), width);
```

### Reading Content

```rust
let cell = buf.get(x, y);
cell.symbol();   // &str
cell.fg;         // Color
cell.bg;         // Color
cell.modifier;   // Modifier
```

---

## Coordinate System

The `area` parameter provides the region to render in:

```rust
impl Widget for MyWidget {
    fn render(self, area: Rect, buf: &mut Buffer) {
        // area.x, area.y = top-left corner
        // area.width, area.height = dimensions

        // Always offset from area origin!
        for y in 0..area.height {
            for x in 0..area.width {
                buf.get_mut(area.x + x, area.y + y)
                    .set_char('·');
            }
        }
    }
}
```

**Important**: When inside borders or nested layouts, `area.x` and `area.y` are not zero. Always add them to your coordinates.

---

## Composability

Custom widgets work with standard widgets and layouts.

```rust
fn render(&self, frame: &mut Frame) {
    let [left, right] = Layout::horizontal([
        Constraint::Percentage(50),
        Constraint::Percentage(50),
    ]).areas(frame.area());

    // Standard widget
    frame.render_widget(Paragraph::new("Standard"), left);

    // Custom widget
    frame.render_widget(MyWidget::new(), right);
}
```

### Inside a Block

```rust
let block = Block::bordered().title("Custom");
let inner = block.inner(area);
frame.render_widget(block, area);
frame.render_widget(MyWidget::new(), inner);
```

---

## Stateful Custom Widgets

For widgets that need mutable state:

```rust
pub trait StatefulWidget {
    type State;
    fn render(self, area: Rect, buf: &mut Buffer, state: &mut Self::State);
}

struct MyListWidget {
    items: Vec<String>,
}

struct MyListState {
    selected: usize,
    offset: usize,
}

impl StatefulWidget for MyListWidget {
    type State = MyListState;

    fn render(self, area: Rect, buf: &mut Buffer, state: &mut Self::State) {
        for (i, item) in self.items.iter().enumerate().skip(state.offset) {
            let y = area.y + (i - state.offset) as u16;
            if y >= area.y + area.height {
                break;
            }

            let style = if i == state.selected {
                Style::new().reversed()
            } else {
                Style::new()
            };

            buf.set_string(area.x, y, item, style);
        }
    }
}

// Usage
frame.render_stateful_widget(MyListWidget { items }, area, &mut state);
```

---

## Example: Progress Bar

```rust
struct ProgressBar {
    ratio: f64,
    label: Option<String>,
    style: Style,
}

impl ProgressBar {
    fn new(ratio: f64) -> Self {
        Self {
            ratio: ratio.clamp(0.0, 1.0),
            label: None,
            style: Style::new().fg(Color::Green),
        }
    }

    fn label(mut self, label: impl Into<String>) -> Self {
        self.label = Some(label.into());
        self
    }

    fn style(mut self, style: Style) -> Self {
        self.style = style;
        self
    }
}

impl Widget for ProgressBar {
    fn render(self, area: Rect, buf: &mut Buffer) {
        if area.height < 1 {
            return;
        }

        let filled = (area.width as f64 * self.ratio) as u16;

        // Draw filled portion
        for x in 0..filled {
            buf.get_mut(area.x + x, area.y)
                .set_char('█')
                .set_style(self.style);
        }

        // Draw empty portion
        for x in filled..area.width {
            buf.get_mut(area.x + x, area.y)
                .set_char('░')
                .set_style(Style::new().fg(Color::DarkGray));
        }

        // Draw label centered
        if let Some(label) = self.label {
            let label_x = area.x + (area.width.saturating_sub(label.len() as u16)) / 2;
            buf.set_string(label_x, area.y, &label, Style::new().bold());
        }
    }
}
```

---

## Example: Sparkline

```rust
struct MiniSparkline<'a> {
    data: &'a [u64],
    style: Style,
}

impl<'a> MiniSparkline<'a> {
    const BARS: [char; 8] = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

    fn new(data: &'a [u64]) -> Self {
        Self {
            data,
            style: Style::new().fg(Color::Cyan),
        }
    }
}

impl Widget for MiniSparkline<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        if self.data.is_empty() || area.height < 1 {
            return;
        }

        let max = *self.data.iter().max().unwrap_or(&1);
        let max = if max == 0 { 1 } else { max };

        for (i, &value) in self.data.iter().take(area.width as usize).enumerate() {
            let bar_idx = ((value as f64 / max as f64) * 7.0) as usize;
            let bar = Self::BARS[bar_idx.min(7)];

            buf.get_mut(area.x + i as u16, area.y)
                .set_char(bar)
                .set_style(self.style);
        }
    }
}
```

---

## Example: Box Drawing

```rust
struct SimpleBox {
    style: Style,
}

impl Widget for SimpleBox {
    fn render(self, area: Rect, buf: &mut Buffer) {
        if area.width < 2 || area.height < 2 {
            return;
        }

        let right = area.x + area.width - 1;
        let bottom = area.y + area.height - 1;

        // Corners
        buf.get_mut(area.x, area.y).set_char('┌').set_style(self.style);
        buf.get_mut(right, area.y).set_char('┐').set_style(self.style);
        buf.get_mut(area.x, bottom).set_char('└').set_style(self.style);
        buf.get_mut(right, bottom).set_char('┘').set_style(self.style);

        // Horizontal lines
        for x in (area.x + 1)..right {
            buf.get_mut(x, area.y).set_char('─').set_style(self.style);
            buf.get_mut(x, bottom).set_char('─').set_style(self.style);
        }

        // Vertical lines
        for y in (area.y + 1)..bottom {
            buf.get_mut(area.x, y).set_char('│').set_style(self.style);
            buf.get_mut(right, y).set_char('│').set_style(self.style);
        }
    }
}
```

---

## Testing Custom Widgets

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::buffer::Buffer;

    #[test]
    fn test_progress_bar() {
        let area = Rect::new(0, 0, 10, 1);
        let mut buf = Buffer::empty(area);

        ProgressBar::new(0.5).render(area, &mut buf);

        // Check filled portion
        assert_eq!(buf.get(0, 0).symbol(), "█");
        assert_eq!(buf.get(4, 0).symbol(), "█");

        // Check empty portion
        assert_eq!(buf.get(5, 0).symbol(), "░");
        assert_eq!(buf.get(9, 0).symbol(), "░");
    }
}
```

---

## Builder Pattern

```rust
struct MyWidget {
    title: String,
    style: Style,
    show_border: bool,
}

impl MyWidget {
    fn new(title: impl Into<String>) -> Self {
        Self {
            title: title.into(),
            style: Style::default(),
            show_border: true,
        }
    }

    fn style(mut self, style: Style) -> Self {
        self.style = style;
        self
    }

    fn border(mut self, show: bool) -> Self {
        self.show_border = show;
        self
    }
}

// Usage
MyWidget::new("Title")
    .style(Style::new().fg(Color::Yellow))
    .border(false)
```
