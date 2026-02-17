# RatatuiRuby Layout

Constraint-based layouts that adapt to terminal size.

## Layout.split

Split an area into regions using constraints.

```ruby
areas = Layout.split(
  frame.area,
  direction: :vertical,         # or :horizontal
  constraints: [
    Constraint.length(3),       # Fixed 3 rows
    Constraint.fill(1),         # Remaining space
    Constraint.length(1)        # Fixed 1 row
  ]
)

# areas[0] = header (3 rows)
# areas[1] = content (fills)
# areas[2] = footer (1 row)
```

### TUI Shorthand

```ruby
tui.layout_split(frame.area, direction: :horizontal, constraints: [
  tui.constraint_length(20),
  tui.constraint_fill(1)
])
```

---

## Constraints

### Length

Fixed size in cells.

```ruby
Constraint.length(10)   # Exactly 10 cells
```

### Percentage

Percentage of available space.

```ruby
Constraint.percentage(50)   # 50% of area
```

### Min / Max

Minimum or maximum size.

```ruby
Constraint.min(5)    # At least 5 cells, grows if space permits
Constraint.max(20)   # At most 20 cells, shrinks if needed
```

### Fill

Proportional distribution of remaining space (like flex-grow).

```ruby
Constraint.fill(1)   # Equal share
Constraint.fill(2)   # Double share

# Example: sidebar (1x) + content (2x)
constraints: [Constraint.fill(1), Constraint.fill(2)]
```

### Ratio

Exact fraction of space.

```ruby
Constraint.ratio(1, 3)   # 1/3rd of area
Constraint.ratio(2, 5)   # 2/5ths
```

---

## Batch Creation

Create multiple constraints at once.

```ruby
Constraint.from_lengths([10, 20, 10])
# => [Constraint.length(10), Constraint.length(20), Constraint.length(10)]

Constraint.from_percentages([25, 50, 25])
Constraint.from_mins([5, 10, 5])
Constraint.from_fills([1, 2, 1])
Constraint.from_ratios([[1, 4], [2, 4], [1, 4]])
```

---

## Rect

Rectangle with position and size.

```ruby
rect = Rect.new(x: 0, y: 0, width: 80, height: 24)

rect.x          # Left edge
rect.y          # Top edge
rect.width      # Width in cells
rect.height     # Height in cells
rect.right      # x + width
rect.bottom     # y + height
rect.area       # width * height
```

### Frame Area

```ruby
tui.draw do |frame|
  frame.area    # Full terminal area as Rect
end
```

---

## Nested Layouts

Compose layouts by splitting recursively.

```ruby
# Main layout: sidebar + content
main = Layout.split(frame.area, direction: :horizontal, constraints: [
  Constraint.length(25),
  Constraint.fill(1)
])
sidebar_area = main[0]
content_area = main[1]

# Split content: header + body + footer
content = Layout.split(content_area, direction: :vertical, constraints: [
  Constraint.length(3),
  Constraint.fill(1),
  Constraint.length(1)
])
header_area = content[0]
body_area = content[1]
footer_area = content[2]
```

---

## Inner Area

Calculate space inside a bordered block.

```ruby
block = Block.new(borders: [:all])
frame.render_widget(block, area)

# Inner area (1-cell border)
inner = Rect.new(
  x: area.x + 1,
  y: area.y + 1,
  width: [area.width - 2, 0].max,
  height: [area.height - 2, 0].max
)
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

```ruby
cols = Layout.split(frame.area, direction: :horizontal, constraints: [
  Constraint.length(20),
  Constraint.fill(1)
])

rows = Layout.split(cols[1], direction: :vertical, constraints: [
  Constraint.length(3),
  Constraint.fill(1),
  Constraint.length(1)
])

sidebar = cols[0]
header = rows[0]
content = rows[1]
footer = rows[2]
```

### Equal Columns

```ruby
Layout.split(area, direction: :horizontal, constraints: [
  Constraint.percentage(33),
  Constraint.percentage(34),
  Constraint.percentage(33)
])
```

### Responsive (Min + Fill)

```ruby
# Sidebar shrinks below content
Layout.split(area, direction: :horizontal, constraints: [
  Constraint.min(15),    # Sidebar at least 15
  Constraint.fill(1)     # Content takes rest
])
```
