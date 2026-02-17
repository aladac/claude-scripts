# RatatuiRuby Custom Widgets

Build anything. Escape the widget library.

## Terminal Capabilities

Terminals have character cells, not pixels. Each cell holds:
- One Unicode character
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

## The Contract

Any Ruby object with `render(area)` works as a widget.

```ruby
class MyWidget
  def render(area)
    # area is a Rect with x, y, width, height
    # Return an array of Draw commands
  end
end
```

---

## Draw Commands

| Command | Purpose |
|---------|---------|
| `Draw.string(x, y, text, style)` | Draw styled string at coordinates |
| `Draw.cell(x, y, cell)` | Draw single cell (character + style) |

### Basic Example

```ruby
class HelloWidget
  def render(area)
    [
      RatatuiRuby::Draw.string(
        area.x,
        area.y,
        "Hello, World!",
        RatatuiRuby::Style::Style.new(fg: :green, modifiers: [:bold])
      )
    ]
  end
end
```

---

## Coordinate Offsets

The `area.x` and `area.y` are not always zero. When inside borders or nested layouts, the origin shifts.

**Always add `area.x` and `area.y` to coordinates.**

```ruby
class DiagonalWidget
  def render(area)
    (0...area.height).filter_map do |i|
      next if i >= area.width  # Stay within bounds

      RatatuiRuby::Draw.string(
        area.x + i,  # Offset from area origin
        area.y + i,
        "\\",
        RatatuiRuby::Style::Style.new(fg: :red)
      )
    end
  end
end
```

---

## Composability

Custom widgets work with standard widgets and layouts.

```ruby
RatatuiRuby.run do |tui|
  tui.draw do |frame|
    areas = tui.layout_split(
      frame.area,
      direction: :horizontal,
      constraints: [tui.constraint_percentage(50), tui.constraint_percentage(50)]
    )

    # Standard widget on the left
    frame.render_widget(tui.paragraph(text: "Standard"), areas[0])

    # Custom widget on the right
    frame.render_widget(DiagonalWidget.new, areas[1])
  end
end
```

### Inside a Block

```ruby
tui.draw do |frame|
  # Render the block frame
  block = tui.block(title: "Custom", borders: [:all])
  frame.render_widget(block, frame.area)

  # Calculate inner area (1-cell border on all sides)
  inner = tui.rect(
    x: frame.area.x + 1,
    y: frame.area.y + 1,
    width: [frame.area.width - 2, 0].max,
    height: [frame.area.height - 2, 0].max
  )

  # Render custom widget inside
  frame.render_widget(MyWidget.new, inner)
end
```

---

## In Layout Trees

Custom widgets work as children in Layout trees.

```ruby
layout = RatatuiRuby::Layout::Layout.new(
  direction: :vertical,
  constraints: [
    RatatuiRuby::Layout::Constraint.length(1),
    RatatuiRuby::Layout::Constraint.fill(1),
  ],
  children: [
    RatatuiRuby::Widgets::Paragraph.new(text: "Header"),
    MyCustomWidget.new,  # Your widget here
  ]
)

RatatuiRuby.draw(layout)
```

---

## Testing Custom Widgets

### Direct Testing

Custom widgets return arrays. Call `render` directly.

```ruby
def test_hello_widget_output
  area = RatatuiRuby::Rect.new(x: 0, y: 0, width: 20, height: 5)
  widget = HelloWidget.new
  commands = widget.render(area)

  assert_equal 1, commands.length
  assert_equal 0, commands[0].x
  assert_equal 0, commands[0].y
  assert_equal "Hello, World!", commands[0].string
end
```

### Visual Testing

Use the test helper to render to a buffer.

```ruby
class TestMyWidget < Minitest::Test
  include RatatuiRuby::TestHelper

  def test_renders_in_terminal
    with_test_terminal(10, 5) do
      RatatuiRuby.draw(MyWidget.new)
      assert_equal "Expected  ", buffer_content[0]
    end
  end
end
```

---

## Type Signatures (RBS)

```rbs
# my_widget.rbs
class MyWidget
  def render: (RatatuiRuby::Rect area) -> Array[RatatuiRuby::Draw::StringCmd | RatatuiRuby::Draw::CellCmd]
end
```

The interface uses structural typing. Any class with matching `render` signature satisfies it.

---

## Example: Progress Bar

```ruby
class SimpleProgress
  def initialize(progress:, width: nil)
    @progress = progress.clamp(0.0, 1.0)
    @width = width
  end

  def render(area)
    width = @width || area.width
    filled = (width * @progress).round
    empty = width - filled

    bar = "█" * filled + "░" * empty

    [
      RatatuiRuby::Draw.string(
        area.x,
        area.y,
        bar,
        RatatuiRuby::Style::Style.new(fg: :green)
      )
    ]
  end
end
```

---

## Example: Sparkline

```ruby
class MiniSparkline
  BLOCKS = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

  def initialize(data:)
    @data = data
  end

  def render(area)
    return [] if @data.empty?

    max = @data.max.to_f
    max = 1.0 if max.zero?

    chars = @data.last(area.width).map do |v|
      idx = ((v / max) * 8).round.clamp(0, 8)
      BLOCKS[idx]
    end

    [
      RatatuiRuby::Draw.string(
        area.x,
        area.y,
        chars.join,
        RatatuiRuby::Style::Style.new(fg: :cyan)
      )
    ]
  end
end
```

---

## Example: Box Drawing

```ruby
class SimpleBox
  def render(area)
    return [] if area.width < 2 || area.height < 2

    commands = []
    style = RatatuiRuby::Style::Style.new(fg: :white)

    # Corners
    commands << draw_char(area.x, area.y, "┌", style)
    commands << draw_char(area.x + area.width - 1, area.y, "┐", style)
    commands << draw_char(area.x, area.y + area.height - 1, "└", style)
    commands << draw_char(area.x + area.width - 1, area.y + area.height - 1, "┘", style)

    # Horizontal lines
    (1...(area.width - 1)).each do |x|
      commands << draw_char(area.x + x, area.y, "─", style)
      commands << draw_char(area.x + x, area.y + area.height - 1, "─", style)
    end

    # Vertical lines
    (1...(area.height - 1)).each do |y|
      commands << draw_char(area.x, area.y + y, "│", style)
      commands << draw_char(area.x + area.width - 1, area.y + y, "│", style)
    end

    commands
  end

  private

  def draw_char(x, y, char, style)
    RatatuiRuby::Draw.string(x, y, char, style)
  end
end
```
