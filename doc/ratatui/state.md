# RatatuiRuby State Management

## Stateless vs Stateful Widgets

Most widgets are **stateless** — you create them each frame with explicit properties:

```ruby
# Stateless: selection is in widget config
List.new(items: items, selected_index: @selected)
```

Some widgets support **stateful rendering** — a mutable State object tracks selection/scroll:

```ruby
# Stateful: selection is in State object
@list_state = ListState.new
@list_state.select(2)
frame.render_stateful_widget(list, area, @list_state)
```

---

## When to Use Stateful Rendering

Use `render_stateful_widget` when you need to:

1. **Read back scroll offset** calculated by Ratatui (for mouse hit testing)
2. **Auto-scroll to selection** without manual offset math
3. **Use navigation helpers** like `select_next`, `select_previous`

---

## ListState

Mutable state for List widgets.

```ruby
@list_state = ListState.new

# Selection
@list_state.select(0)           # Select first item
@list_state.select(nil)         # Deselect
@list_state.selected            # => Integer or nil

# Navigation
@list_state.select_next         # Move down
@list_state.select_previous     # Move up
@list_state.select_first        # Jump to top
@list_state.select_last         # Jump to bottom

# Scrolling
@list_state.scroll_down_by(5)
@list_state.scroll_up_by(5)
@list_state.offset              # Current scroll position
```

### Usage

```ruby
@list_state = ListState.new
@list_state.select(0)

RatatuiRuby.run do |tui|
  loop do
    tui.draw do |frame|
      list = tui.list(
        items: @items,
        highlight_style: tui.style(modifiers: [:reversed])
      )
      frame.render_stateful_widget(list, frame.area, @list_state)
    end

    case tui.poll_event
    in { type: :key, code: "down" }
      @list_state.select_next
    in { type: :key, code: "up" }
      @list_state.select_previous
    in { type: :key, code: "q" }
      break
    else
      nil
    end
  end
end
```

---

## TableState

Mutable state for Table widgets.

```ruby
@table_state = TableState.new

# Row selection
@table_state.select_row(0)
@table_state.selected_row       # => Integer or nil
@table_state.select_next_row
@table_state.select_previous_row

# Column selection
@table_state.select_column(1)
@table_state.selected_column    # => Integer or nil

# Scroll
@table_state.offset             # Read back after render
```

---

## ScrollbarState

State for Scrollbar widgets.

```ruby
@scrollbar_state = ScrollbarState.new(content_length: 100, viewport_content_length: 20)

# Position
@scrollbar_state.position = 25
@scrollbar_state.position       # => 25

# Scrolling
@scrollbar_state.scroll_down(5)
@scrollbar_state.scroll_up(5)
@scrollbar_state.first          # Scroll to top
@scrollbar_state.last           # Scroll to bottom
```

---

## Precedence Rules

When using `render_stateful_widget`, **State takes precedence over widget properties**:

```ruby
# Widget says selected_index: 0, State says select(5)
# Result: item 5 is highlighted
list = List.new(items: items, selected_index: 0)
@state.select(5)
frame.render_stateful_widget(list, area, @state)
```

Widget properties for selection/offset are **ignored** in stateful mode.

---

## Optimistic Indexing

Navigation methods (`select_next`, `select_last`) use "optimistic indexing":

- They set index immediately, even past bounds
- The renderer clamps to valid range on draw
- Reading `selected` between call and render may return out-of-bounds

To detect actual bounds:

```ruby
max_index = items.size - 1
return if (@list_state.selected || 0) >= max_index
@list_state.select_next
```

---

## Thread/Ractor Safety

State objects are **NOT Ractor-shareable** — they contain mutable internal state.

```ruby
# Good: Store in instance variable
@list_state = ListState.new

# Bad: Include in immutable Model
Model = Data.define(:state)  # Don't do this with State objects
```

---

## Pattern: Model-State Split

Keep application data in immutable Model, widget state in mutable State:

```ruby
Model = Data.define(:items, :filter)

class App
  def initialize
    @model = Model.new(items: fetch_items, filter: "")
    @list_state = ListState.new
  end

  def update(msg)
    case msg
    in :next
      @list_state.select_next
    in :filter, value
      @model = @model.with(filter: value, items: filter_items(value))
      @list_state.select_first  # Reset selection on filter
    end
  end

  def view(tui, frame)
    list = tui.list(items: @model.items)
    frame.render_stateful_widget(list, frame.area, @list_state)
  end
end
```
