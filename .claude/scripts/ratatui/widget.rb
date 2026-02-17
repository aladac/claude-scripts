#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiWidget < Claude::Generator
  METADATA = { name: "ratatui:widget", desc: "Quick widget reference" }.freeze

  WIDGETS = {
    "paragraph" => {
      desc: "Display text with alignment and wrapping",
      opts: "text:, style:, alignment:, wrap:, scroll:, block:",
      example: <<~RUBY
        Paragraph.new(
          text: "Hello, World!",
          style: Style.new(fg: :green),
          alignment: :center,
          wrap: true,
          block: Block.new(title: "Output", borders: [:all])
        )
      RUBY
    },
    "list" => {
      desc: "Selectable list with navigation",
      opts: "items:, selected_index:, highlight_style:, highlight_symbol:, direction:, scroll_padding:, block:",
      example: <<~RUBY
        List.new(
          items: ["Item 1", "Item 2", "Item 3"],
          selected_index: 0,
          highlight_style: Style.new(modifiers: [:reversed]),
          highlight_symbol: ">> ",
          block: Block.new(title: "Menu", borders: [:all])
        )
      RUBY
    },
    "table" => {
      desc: "Structured data in rows and columns",
      opts: "header:, rows:, widths:, selected_row:, row_highlight_style:, column_spacing:, block:",
      example: <<~RUBY
        Table.new(
          header: ["Name", "Status", "Port"],
          rows: [["api", "running", "8080"], ["worker", "stopped", "-"]],
          widths: [Constraint.percentage(40), Constraint.percentage(30), Constraint.percentage(30)],
          selected_row: 0,
          row_highlight_style: Style.new(modifiers: [:reversed])
        )
      RUBY
    },
    "block" => {
      desc: "Container with borders and title",
      opts: "title:, borders:, border_style:, border_type:, title_position:, title_alignment:",
      example: <<~RUBY
        Block.new(
          title: "Dashboard",
          borders: [:all],
          border_type: :rounded,
          border_style: Style.new(fg: :cyan)
        )
      RUBY
    },
    "gauge" => {
      desc: "Progress indicator",
      opts: "ratio:, label:, style:, gauge_style:, block:",
      example: <<~RUBY
        Gauge.new(
          ratio: 0.75,
          label: "75%",
          gauge_style: Style.new(bg: :green),
          block: Block.new(title: "Progress", borders: [:all])
        )
      RUBY
    },
    "linegauge" => {
      desc: "Horizontal line progress",
      opts: "ratio:, label:, line_set:, filled_style:, unfilled_style:",
      example: <<~RUBY
        LineGauge.new(
          ratio: 0.5,
          label: "Loading...",
          line_set: :thick,
          filled_style: Style.new(fg: :blue)
        )
      RUBY
    },
    "tabs" => {
      desc: "Tab bar",
      opts: "titles:, selected:, style:, highlight_style:, divider:, block:",
      example: <<~RUBY
        Tabs.new(
          titles: ["Home", "Settings", "Help"],
          selected: 0,
          highlight_style: Style.new(fg: :yellow, modifiers: [:bold]),
          divider: " | "
        )
      RUBY
    },
    "sparkline" => {
      desc: "Mini chart for data series",
      opts: "data:, style:, direction:, block:",
      example: <<~RUBY
        Sparkline.new(
          data: [1, 4, 2, 8, 5, 7, 3],
          style: Style.new(fg: :cyan),
          direction: :left_to_right
        )
      RUBY
    },
    "scrollbar" => {
      desc: "Scroll indicator",
      opts: "orientation:, thumb_style:, track_style:, begin_symbol:, end_symbol:",
      example: <<~RUBY
        Scrollbar.new(
          orientation: :vertical,
          thumb_style: Style.new(fg: :cyan),
          track_style: Style.new(fg: :dark_gray)
        )
      RUBY
    },
    "canvas" => {
      desc: "Low-level drawing surface",
      opts: "x_bounds:, y_bounds:, marker:, paint:",
      example: <<~RUBY
        Canvas.new(
          x_bounds: [0.0, 100.0],
          y_bounds: [0.0, 100.0],
          marker: :braille,
          paint: ->(ctx) {
            ctx.draw(Line.new(x1: 0, y1: 0, x2: 100, y2: 100, color: :red))
          }
        )
      RUBY
    }
  }.freeze

  def execute
    widget = args.first&.downcase

    if widget.nil? || widget.empty?
      list_widgets
    elsif WIDGETS.key?(widget)
      show_widget(widget)
    else
      err "Unknown widget: #{widget}"
      puts
      list_widgets
    end
  end

  private

  def list_widgets
    section "Available Widgets"

    rows = WIDGETS.map do |name, info|
      [name, info[:desc]]
    end

    table(%w[Widget Description], rows)

    puts
    info "Usage: /ratatui:widget <name>"
  end

  def show_widget(name)
    widget = WIDGETS[name]
    section name.capitalize

    bold "Description"
    info widget[:desc]

    puts
    bold "Options"
    info widget[:opts]

    puts
    bold "Example"
    puts widget[:example]
  end
end

RatatuiWidget.run
