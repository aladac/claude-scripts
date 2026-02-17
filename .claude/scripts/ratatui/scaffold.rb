#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiScaffold < Claude::Generator
  METADATA = { name: "ratatui:scaffold", desc: "Scaffold Rust TUI app" }.freeze

  TEMPLATES = {
    "basic" => "Minimal app with event loop",
    "list" => "Interactive list with navigation",
    "dashboard" => "Multi-pane layout with header/footer"
  }.freeze

  def execute
    name = args.shift
    template = args.shift || "basic"

    if name.nil? || name.empty?
      show_usage
      return
    end

    unless TEMPLATES.key?(template)
      err "Unknown template: #{template}"
      show_usage
      return
    end

    generate(name, template)
  end

  private

  def show_usage
    section "Scaffold Templates"

    rows = TEMPLATES.map { |name, desc| [name, desc] }
    table(%w[Template Description], rows)

    puts
    info "Usage: /ratatui:scaffold <name> [template]"
    info "Example: /ratatui:scaffold my_app list"
  end

  def generate(name, template)
    struct_name = name.split("_").map(&:capitalize).join
    content = send("template_#{template}", name, struct_name)

    section "Generating #{template} scaffold"

    puts "```rust"
    puts "// src/main.rs"
    puts content
    puts "```"

    puts
    info "Cargo.toml dependencies:"
    puts "```toml"
    puts '[dependencies]'
    puts 'ratatui = "0.29"'
    puts 'crossterm = "0.28"'
    puts "```"
  end

  def template_basic(_name, struct_name)
    <<~RUST
      use ratatui::{
          crossterm::event::{self, Event, KeyCode},
          widgets::{Block, Paragraph},
          DefaultTerminal, Frame,
      };

      fn main() -> std::io::Result<()> {
          let mut terminal = ratatui::init();
          let result = run(&mut terminal);
          ratatui::restore();
          result
      }

      fn run(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
          loop {
              terminal.draw(ui)?;

              if let Event::Key(key) = event::read()? {
                  if key.code == KeyCode::Char('q') {
                      break Ok(());
                  }
              }
          }
      }

      fn ui(frame: &mut Frame) {
          frame.render_widget(
              Paragraph::new("Hello, Ratatui! Press 'q' to quit.")
                  .block(Block::bordered().title("#{struct_name}")),
              frame.area(),
          );
      }
    RUST
  end

  def template_list(_name, struct_name)
    <<~RUST
      use ratatui::{
          crossterm::event::{self, Event, KeyCode},
          layout::{Constraint, Layout},
          style::{Style, Stylize},
          widgets::{Block, List, ListItem, ListState},
          DefaultTerminal, Frame,
      };

      struct App {
          items: Vec<String>,
          state: ListState,
          running: bool,
      }

      impl App {
          fn new() -> Self {
              Self {
                  items: vec![
                      "Item 1".into(),
                      "Item 2".into(),
                      "Item 3".into(),
                      "Item 4".into(),
                      "Item 5".into(),
                  ],
                  state: ListState::default().with_selected(Some(0)),
                  running: true,
              }
          }

          fn run(&mut self, terminal: &mut DefaultTerminal) -> std::io::Result<()> {
              while self.running {
                  terminal.draw(|frame| self.render(frame))?;
                  self.handle_events()?;
              }
              Ok(())
          }

          fn render(&mut self, frame: &mut Frame) {
              let items: Vec<ListItem> = self.items
                  .iter()
                  .map(|i| ListItem::new(i.as_str()))
                  .collect();

              let list = List::new(items)
                  .highlight_style(Style::new().reversed())
                  .highlight_symbol(">> ")
                  .block(Block::bordered().title("#{struct_name} [j/k/Enter/q]"));

              frame.render_stateful_widget(list, frame.area(), &mut self.state);
          }

          fn handle_events(&mut self) -> std::io::Result<()> {
              if let Event::Key(key) = event::read()? {
                  match key.code {
                      KeyCode::Char('q') => self.running = false,
                      KeyCode::Down | KeyCode::Char('j') => self.state.select_next(),
                      KeyCode::Up | KeyCode::Char('k') => self.state.select_previous(),
                      KeyCode::Enter => self.handle_selection(),
                      _ => {}
                  }
              }
              Ok(())
          }

          fn handle_selection(&mut self) {
              if let Some(i) = self.state.selected() {
                  // TODO: Handle selection of item i
              }
          }
      }

      fn main() -> std::io::Result<()> {
          let mut terminal = ratatui::init();
          let result = App::new().run(&mut terminal);
          ratatui::restore();
          result
      }
    RUST
  end

  def template_dashboard(_name, struct_name)
    <<~RUST
      use ratatui::{
          crossterm::event::{self, Event, KeyCode},
          layout::{Constraint, Layout},
          style::{Style, Stylize},
          widgets::{Block, Paragraph},
          DefaultTerminal, Frame,
      };

      struct App {
          running: bool,
      }

      impl App {
          fn new() -> Self {
              Self { running: true }
          }

          fn run(&mut self, terminal: &mut DefaultTerminal) -> std::io::Result<()> {
              while self.running {
                  terminal.draw(|frame| self.render(frame))?;
                  self.handle_events()?;
              }
              Ok(())
          }

          fn render(&self, frame: &mut Frame) {
              let [header, content, footer] = Layout::vertical([
                  Constraint::Length(3),
                  Constraint::Fill(1),
                  Constraint::Length(1),
              ]).areas(frame.area());

              self.render_header(frame, header);
              self.render_content(frame, content);
              self.render_footer(frame, footer);
          }

          fn render_header(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
              frame.render_widget(
                  Paragraph::new("#{struct_name}")
                      .centered()
                      .style(Style::new().cyan().bold())
                      .block(Block::default().borders(ratatui::widgets::Borders::BOTTOM)),
                  area,
              );
          }

          fn render_content(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
              let [sidebar, main] = Layout::horizontal([
                  Constraint::Length(20),
                  Constraint::Fill(1),
              ]).areas(area);

              frame.render_widget(
                  Paragraph::new("Sidebar")
                      .block(Block::bordered().title("Nav")),
                  sidebar,
              );
              frame.render_widget(
                  Paragraph::new("Main content area")
                      .block(Block::bordered().title("Content")),
                  main,
              );
          }

          fn render_footer(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
              frame.render_widget(
                  Paragraph::new(" q: Quit | Tab: Switch pane ")
                      .style(Style::new().dark_gray()),
                  area,
              );
          }

          fn handle_events(&mut self) -> std::io::Result<()> {
              if let Event::Key(key) = event::read()? {
                  match key.code {
                      KeyCode::Char('q') => self.running = false,
                      _ => {}
                  }
              }
              Ok(())
          }
      }

      fn main() -> std::io::Result<()> {
          let mut terminal = ratatui::init();
          let result = App::new().run(&mut terminal);
          ratatui::restore();
          result
      }
    RUST
  end
end

RatatuiScaffold.run
