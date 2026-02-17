#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiWidget < Claude::Generator
  METADATA = { name: "ratatui:widget", desc: "Widget quick reference" }.freeze

  WIDGETS = {
    "paragraph" => {
      desc: "Display text with alignment and wrapping",
      example: <<~RUST
        use ratatui::widgets::{Paragraph, Block, Wrap};
        use ratatui::style::Style;
        use ratatui::layout::Alignment;

        Paragraph::new("Hello, World!")
            .style(Style::new().fg(Color::Green))
            .alignment(Alignment::Center)
            .wrap(Wrap { trim: true })
            .block(Block::bordered().title("Output"))
      RUST
    },
    "list" => {
      desc: "Selectable list with navigation",
      example: <<~RUST
        use ratatui::widgets::{List, ListItem, ListState, Block};
        use ratatui::style::Style;

        let items = vec![
            ListItem::new("Item 1"),
            ListItem::new("Item 2"),
            ListItem::new("Item 3"),
        ];

        let list = List::new(items)
            .highlight_style(Style::new().reversed())
            .highlight_symbol(">> ")
            .block(Block::bordered().title("Menu"));

        // Render with state
        let mut state = ListState::default().with_selected(Some(0));
        frame.render_stateful_widget(list, area, &mut state);

        // Navigation
        state.select_next();
        state.select_previous();
      RUST
    },
    "table" => {
      desc: "Structured data in rows and columns",
      example: <<~RUST
        use ratatui::widgets::{Table, Row, Cell, TableState, Block};
        use ratatui::layout::Constraint;
        use ratatui::style::Style;

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
            .block(Block::bordered().title("Services"));

        let mut state = TableState::default().with_selected(Some(0));
        frame.render_stateful_widget(table, area, &mut state);
      RUST
    },
    "block" => {
      desc: "Container with borders and title",
      example: <<~RUST
        use ratatui::widgets::{Block, Borders, BorderType};
        use ratatui::style::Style;
        use ratatui::layout::Alignment;

        Block::new()
            .title("Dashboard")
            .borders(Borders::ALL)
            .border_style(Style::new().fg(Color::Cyan))
            .border_type(BorderType::Rounded)
            .title_alignment(Alignment::Center)

        // Shorthand
        Block::bordered().title("Title")

        // Get inner area
        let inner = block.inner(area);
      RUST
    },
    "gauge" => {
      desc: "Progress indicator",
      example: <<~RUST
        use ratatui::widgets::{Gauge, Block};
        use ratatui::style::Style;

        Gauge::default()
            .ratio(0.75)  // 0.0 to 1.0
            .label("75%")
            .gauge_style(Style::new().fg(Color::Green))
            .block(Block::bordered().title("Progress"))
      RUST
    },
    "tabs" => {
      desc: "Tab bar for navigation",
      example: <<~RUST
        use ratatui::widgets::{Tabs, Block, Borders};
        use ratatui::style::Style;

        Tabs::new(vec!["Home", "Settings", "Help"])
            .select(0)
            .style(Style::new().fg(Color::White))
            .highlight_style(Style::new().fg(Color::Yellow).bold())
            .divider(" | ")
            .block(Block::default().borders(Borders::BOTTOM))
      RUST
    },
    "sparkline" => {
      desc: "Mini chart for data series",
      example: <<~RUST
        use ratatui::widgets::{Sparkline, Block, RenderDirection};
        use ratatui::style::Style;

        Sparkline::default()
            .data(&[1, 4, 2, 8, 5, 7, 3])
            .style(Style::new().fg(Color::Cyan))
            .direction(RenderDirection::LeftToRight)
            .block(Block::bordered())
      RUST
    },
    "scrollbar" => {
      desc: "Scroll indicator",
      example: <<~RUST
        use ratatui::widgets::{Scrollbar, ScrollbarOrientation, ScrollbarState};
        use ratatui::style::Style;

        let scrollbar = Scrollbar::new(ScrollbarOrientation::VerticalRight)
            .thumb_style(Style::new().fg(Color::Cyan))
            .track_style(Style::new().fg(Color::DarkGray));

        let mut state = ScrollbarState::new(100).position(25);
        frame.render_stateful_widget(scrollbar, area, &mut state);
      RUST
    },
    "canvas" => {
      desc: "Low-level drawing surface",
      example: <<~RUST
        use ratatui::widgets::canvas::{Canvas, Line, Circle};
        use ratatui::symbols::Marker;

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
      RUST
    },
    "barchart" => {
      desc: "Vertical/horizontal bar chart",
      example: <<~RUST
        use ratatui::widgets::{BarChart, Bar, BarGroup};
        use ratatui::style::Style;

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
      RUST
    }
  }.freeze

  def execute
    name = args.first&.downcase

    if name.nil? || name.empty?
      show_all
      return
    end

    widget = WIDGETS[name]
    if widget.nil?
      err "Unknown widget: #{name}"
      puts
      show_all
      return
    end

    show_widget(name, widget)
  end

  private

  def show_all
    section "Available Widgets"

    rows = WIDGETS.map { |name, w| [name, w[:desc]] }
    table(%w[Widget Description], rows)

    puts
    info "Usage: /ratatui:widget <name>"
  end

  def show_widget(name, widget)
    section name.capitalize

    puts widget[:desc]
    puts
    puts "```rust"
    puts widget[:example].strip
    puts "```"
  end
end

RatatuiWidget.run
