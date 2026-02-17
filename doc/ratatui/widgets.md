# RatatuiRuby Widgets

All widgets are immutable `Data.define` objects. Create them with keyword arguments.

## Widget Categories

| Category | Widgets |
|----------|---------|
| **Text** | Paragraph, Cursor |
| **Data** | List, Table, Sparkline, BarChart, Chart, Calendar |
| **Layout** | Block, Tabs, Scrollbar, Center, Overlay, Clear |
| **Input** | Gauge, LineGauge |
| **Canvas** | Canvas (shapes, custom drawing) |

---

## Paragraph

Display text with alignment, wrapping, and scrolling.

```ruby
Paragraph.new(
  text: "Hello, World!",
  style: Style.new(fg: :green),
  alignment: :center,        # :left, :center, :right
  wrap: true,                # wrap at container edge
  scroll: [0, 0],            # [y, x] offset
  block: Block.new(title: "Output", borders: [:all])
)
```

### Rich Text

```ruby
Paragraph.new(
  text: Text::Line.new(spans: [
    Text::Span.new(content: "Error: ", style: Style.new(fg: :red, modifiers: [:bold])),
    Text::Span.new(content: "File not found")
  ])
)
```

---

## List

Selectable list with navigation and scrolling.

```ruby
List.new(
  items: ["Item 1", "Item 2", "Item 3"],
  selected_index: 0,
  highlight_style: Style.new(bg: :blue),
  highlight_symbol: ">> ",
  highlight_spacing: :when_selected,  # :always, :when_selected, :never
  direction: :top_to_bottom,          # or :bottom_to_top
  scroll_padding: 2,
  block: Block.new(title: "Menu", borders: [:all])
)
```

### List with Styled Items

```ruby
items = [
  ListItem.new(content: "Active", style: Style.new(fg: :green)),
  ListItem.new(content: "Pending", style: Style.new(fg: :yellow)),
  ListItem.new(content: "Error", style: Style.new(fg: :red))
]
List.new(items: items)
```

---

## Table

Structured data in rows and columns.

```ruby
Table.new(
  header: ["Name", "Status", "Port"],
  rows: [
    ["api", "running", "8080"],
    ["worker", "stopped", "-"]
  ],
  widths: [
    Constraint.percentage(40),
    Constraint.percentage(30),
    Constraint.percentage(30)
  ],
  selected_row: 0,
  row_highlight_style: Style.new(modifiers: [:reversed]),
  highlight_symbol: "> ",
  column_spacing: 1,
  block: Block.new(title: "Services", borders: [:all])
)
```

### Width Shortcuts

```ruby
# Integers auto-coerce to Constraint.length
Table.new(widths: [20, 15, 10])

# Batch creation
Constraint.from_percentages([40, 30, 30])
Constraint.from_lengths([20, 15, 10])
```

---

## Block

Container with borders and title.

```ruby
Block.new(
  title: "Dashboard",
  borders: [:all],              # [:top, :bottom, :left, :right] or [:all]
  border_style: Style.new(fg: :cyan),
  border_type: :rounded,        # :plain, :rounded, :double, :thick
  title_position: :top,         # :top, :bottom
  title_alignment: :center      # :left, :center, :right
)
```

---

## Gauge

Progress indicator.

```ruby
Gauge.new(
  ratio: 0.75,                  # 0.0 to 1.0
  label: "75%",
  style: Style.new(fg: :green),
  gauge_style: Style.new(bg: :green),
  block: Block.new(title: "Progress", borders: [:all])
)
```

---

## LineGauge

Horizontal line progress.

```ruby
LineGauge.new(
  ratio: 0.5,
  label: "Loading...",
  line_set: :thick,             # :normal, :thick, :double
  filled_style: Style.new(fg: :blue),
  unfilled_style: Style.new(fg: :dark_gray)
)
```

---

## Sparkline

Mini chart for data series.

```ruby
Sparkline.new(
  data: [1, 4, 2, 8, 5, 7, 3],
  style: Style.new(fg: :cyan),
  direction: :left_to_right,    # or :right_to_left
  block: Block.new(borders: [:all])
)
```

---

## BarChart

Vertical bar chart.

```ruby
BarChart.new(
  data: [
    Bar.new(value: 10, label: "Mon"),
    Bar.new(value: 20, label: "Tue"),
    Bar.new(value: 15, label: "Wed")
  ],
  bar_width: 5,
  bar_gap: 1,
  bar_style: Style.new(fg: :blue),
  value_style: Style.new(fg: :white),
  label_style: Style.new(fg: :cyan),
  direction: :vertical          # or :horizontal
)
```

---

## Tabs

Tab bar.

```ruby
Tabs.new(
  titles: ["Home", "Settings", "Help"],
  selected: 0,
  style: Style.new(fg: :white),
  highlight_style: Style.new(fg: :yellow, modifiers: [:bold]),
  divider: " | ",
  block: Block.new(borders: [:bottom])
)
```

---

## Scrollbar

Scroll indicator.

```ruby
Scrollbar.new(
  orientation: :vertical,       # or :horizontal
  thumb_style: Style.new(fg: :cyan),
  track_style: Style.new(fg: :dark_gray),
  begin_symbol: "▲",
  end_symbol: "▼"
)
```

Use with `ScrollbarState` for stateful rendering.

---

## Canvas

Low-level drawing surface for shapes.

```ruby
Canvas.new(
  x_bounds: [0.0, 100.0],
  y_bounds: [0.0, 100.0],
  marker: :braille,             # :braille, :dot, :block, :bar, :half_block
  paint: ->(ctx) {
    ctx.draw(Line.new(x1: 0, y1: 0, x2: 100, y2: 100, color: :red))
    ctx.draw(Circle.new(x: 50, y: 50, radius: 20, color: :blue))
  }
)
```

---

## Center

Center content in area.

```ruby
Center.new(
  child: Paragraph.new(text: "Centered!")
)
```

---

## Overlay

Layer widget on top of another.

```ruby
Overlay.new(
  base: base_widget,
  overlay: popup_widget,
  position: [10, 5]             # [x, y]
)
```

---

## Clear

Clear area (fill with spaces).

```ruby
Clear.new
```

---

## Style Reference

```ruby
Style.new(
  fg: :red,                     # Symbol, "#hex", or Integer (0-255)
  bg: :black,
  underline_color: :yellow,
  modifiers: [:bold, :italic, :underlined, :reversed, :dim, :crossed_out]
)

# Named colors
:black, :red, :green, :yellow, :blue, :magenta, :cyan, :gray, :white
:dark_gray, :light_red, :light_green, :light_yellow, :light_blue, :light_magenta, :light_cyan

# Hex colors (24-bit)
"#ff5500", "#a0b0c0"

# 256-color palette
42, 196, 232
```
