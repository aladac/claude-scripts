#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiExample < Claude::Generator
  METADATA = { name: "ratatui:example", desc: "Show example patterns" }.freeze

  PATTERNS = {
    "layout" => "Nested layouts with constraints",
    "events" => "Pattern matching for input",
    "async" => "Background tasks with Tokio",
    "stateful" => "Interactive list with state",
    "custom-widget" => "Build your own widget",
    "testing" => "Test with TestBackend",
    "mouse" => "Handle mouse events",
    "style" => "Colors and modifiers"
  }.freeze

  EXAMPLES = {
    "layout" => <<~RUST,
      use ratatui::layout::{Constraint, Layout};

      fn render(&self, frame: &mut Frame) {
          // Main: sidebar + content
          let [sidebar, content] = Layout::horizontal([
              Constraint::Length(25),
              Constraint::Fill(1),
          ]).areas(frame.area());

          // Content: header + body + footer
          let [header, body, footer] = Layout::vertical([
              Constraint::Length(3),
              Constraint::Fill(1),
              Constraint::Length(1),
          ]).areas(content);

          frame.render_widget(self.sidebar_widget(), sidebar);
          frame.render_widget(self.header_widget(), header);
          frame.render_widget(self.body_widget(), body);
          frame.render_widget(self.footer_widget(), footer);
      }
    RUST

    "events" => <<~RUST,
      use ratatui::crossterm::event::{self, Event, KeyCode, KeyModifiers, MouseEventKind};

      fn handle_events(&mut self) -> std::io::Result<bool> {
          match event::read()? {
              // Quit on 'q' or Ctrl+C
              Event::Key(key) if key.code == KeyCode::Char('q') => return Ok(false),
              Event::Key(key) if key.code == KeyCode::Char('c')
                  && key.modifiers.contains(KeyModifiers::CONTROL) => return Ok(false),

              // Navigation
              Event::Key(key) => match key.code {
                  KeyCode::Up | KeyCode::Char('k') => self.move_up(),
                  KeyCode::Down | KeyCode::Char('j') => self.move_down(),
                  KeyCode::Enter => self.select(),
                  KeyCode::Char(c) => self.handle_char(c),
                  _ => {}
              },

              // Resize
              Event::Resize(width, height) => {
                  self.size = (width, height);
              }

              _ => {}
          }
          Ok(true)
      }
    RUST

    "async" => <<~RUST,
      use std::sync::mpsc;
      use std::thread;
      use std::time::Duration;

      enum AppEvent {
          Key(KeyEvent),
          Tick,
          TaskComplete(String),
      }

      fn main() -> std::io::Result<()> {
          let (tx, rx) = mpsc::channel();

          // Spawn tick thread
          let tick_tx = tx.clone();
          thread::spawn(move || {
              loop {
                  thread::sleep(Duration::from_millis(100));
                  if tick_tx.send(AppEvent::Tick).is_err() {
                      break;
                  }
              }
          });

          // Spawn background task
          let task_tx = tx.clone();
          thread::spawn(move || {
              // Simulate async work
              thread::sleep(Duration::from_secs(2));
              let result = "Task completed!".to_string();
              let _ = task_tx.send(AppEvent::TaskComplete(result));
          });

          // Event thread for keyboard
          let key_tx = tx.clone();
          thread::spawn(move || {
              loop {
                  if event::poll(Duration::from_millis(50)).unwrap() {
                      if let Event::Key(key) = event::read().unwrap() {
                          if key_tx.send(AppEvent::Key(key)).is_err() {
                              break;
                          }
                      }
                  }
              }
          });

          // Main loop
          loop {
              terminal.draw(|frame| app.render(frame))?;

              match rx.recv()? {
                  AppEvent::Key(key) if key.code == KeyCode::Char('q') => break,
                  AppEvent::TaskComplete(result) => app.task_result = Some(result),
                  AppEvent::Tick => app.tick(),
                  _ => {}
              }
          }
          Ok(())
      }
    RUST

    "stateful" => <<~RUST,
      use ratatui::widgets::{List, ListItem, ListState, Block};
      use ratatui::style::{Style, Stylize};

      struct App {
          items: Vec<String>,
          state: ListState,
      }

      impl App {
          fn new(items: Vec<String>) -> Self {
              Self {
                  items,
                  state: ListState::default().with_selected(Some(0)),
              }
          }

          fn render(&mut self, frame: &mut Frame) {
              let items: Vec<ListItem> = self.items
                  .iter()
                  .map(|i| ListItem::new(i.as_str()))
                  .collect();

              let list = List::new(items)
                  .highlight_style(Style::new().reversed())
                  .highlight_symbol(">> ")
                  .block(Block::bordered().title("Items"));

              frame.render_stateful_widget(list, frame.area(), &mut self.state);
          }

          fn next(&mut self) {
              self.state.select_next();
          }

          fn previous(&mut self) {
              self.state.select_previous();
          }

          fn selected(&self) -> Option<&String> {
              self.state.selected().and_then(|i| self.items.get(i))
          }
      }
    RUST

    "custom-widget" => <<~RUST,
      use ratatui::{
          buffer::Buffer,
          layout::Rect,
          style::{Color, Style},
          widgets::Widget,
      };

      struct ProgressBar {
          ratio: f64,
          style: Style,
      }

      impl ProgressBar {
          fn new(ratio: f64) -> Self {
              Self {
                  ratio: ratio.clamp(0.0, 1.0),
                  style: Style::new().fg(Color::Green),
              }
          }

          fn style(mut self, style: Style) -> Self {
              self.style = style;
              self
          }
      }

      impl Widget for ProgressBar {
          fn render(self, area: Rect, buf: &mut Buffer) {
              let filled = (area.width as f64 * self.ratio) as u16;

              for x in 0..filled {
                  buf.get_mut(area.x + x, area.y)
                      .set_char('█')
                      .set_style(self.style);
              }

              for x in filled..area.width {
                  buf.get_mut(area.x + x, area.y)
                      .set_char('░')
                      .set_style(Style::new().fg(Color::DarkGray));
              }
          }
      }

      // Usage:
      frame.render_widget(ProgressBar::new(0.75), area);
    RUST

    "testing" => <<~RUST,
      use ratatui::{backend::TestBackend, Terminal, widgets::Paragraph};

      #[cfg(test)]
      mod tests {
          use super::*;

          fn buffer_contains(buffer: &ratatui::buffer::Buffer, text: &str) -> bool {
              let content: String = buffer
                  .content()
                  .iter()
                  .map(|cell| cell.symbol())
                  .collect();
              content.contains(text)
          }

          #[test]
          fn test_renders_title() {
              let backend = TestBackend::new(40, 10);
              let mut terminal = Terminal::new(backend).unwrap();

              terminal.draw(|frame| {
                  frame.render_widget(
                      Paragraph::new("My App"),
                      frame.area(),
                  );
              }).unwrap();

              let buffer = terminal.backend().buffer();
              assert!(buffer_contains(buffer, "My App"));
          }

          #[test]
          fn test_handles_quit() {
              use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};

              let mut app = App::new();
              let key = KeyEvent::new(KeyCode::Char('q'), KeyModifiers::empty());

              let should_continue = app.handle_key(key);
              assert!(!should_continue);
          }
      }
    RUST

    "mouse" => <<~RUST,
      use ratatui::crossterm::event::{
          Event, MouseEvent, MouseEventKind, MouseButton,
      };

      fn handle_events(&mut self) -> std::io::Result<()> {
          match event::read()? {
              Event::Mouse(mouse) => match mouse.kind {
                  MouseEventKind::Down(MouseButton::Left) => {
                      self.handle_click(mouse.column, mouse.row);
                  }
                  MouseEventKind::Drag(MouseButton::Left) => {
                      self.handle_drag(mouse.column, mouse.row);
                  }
                  MouseEventKind::ScrollUp => {
                      self.scroll_up();
                  }
                  MouseEventKind::ScrollDown => {
                      self.scroll_down();
                  }
                  _ => {}
              }
              _ => {}
          }
          Ok(())
      }

      // Enable mouse capture in terminal setup:
      fn setup_terminal() -> std::io::Result<Terminal<CrosstermBackend<Stdout>>> {
          enable_raw_mode()?;
          let mut stdout = std::io::stdout();
          execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
          let backend = CrosstermBackend::new(stdout);
          Terminal::new(backend)
      }

      fn restore_terminal() -> std::io::Result<()> {
          disable_raw_mode()?;
          execute!(
              std::io::stdout(),
              LeaveAlternateScreen,
              DisableMouseCapture
          )?;
          Ok(())
      }
    RUST

    "style" => <<~RUST
      use ratatui::style::{Color, Modifier, Style, Stylize};

      // Named colors
      let style = Style::new().fg(Color::Red).bg(Color::Black);
      let style = Style::new().fg(Color::LightBlue).bg(Color::DarkGray);

      // Available colors:
      // Color::Black, Red, Green, Yellow, Blue, Magenta, Cyan, Gray, White
      // Color::DarkGray, LightRed, LightGreen, LightYellow, LightBlue, LightMagenta, LightCyan

      // RGB colors
      let style = Style::new()
          .fg(Color::Rgb(255, 85, 0))
          .bg(Color::Rgb(26, 26, 26));

      // 256-color palette
      let style = Style::new()
          .fg(Color::Indexed(196))  // Bright red
          .bg(Color::Indexed(232)); // Near black

      // Modifiers
      let style = Style::new()
          .add_modifier(Modifier::BOLD)
          .add_modifier(Modifier::ITALIC)
          .add_modifier(Modifier::UNDERLINED)
          .add_modifier(Modifier::REVERSED)
          .add_modifier(Modifier::DIM);

      // Shorthand with Stylize trait
      let style = Style::new().green().bold().on_black();
      let style = Style::new().red().italic().underlined();

      // Combined
      let style = Style::new()
          .fg(Color::Green)
          .bg(Color::Black)
          .add_modifier(Modifier::BOLD | Modifier::UNDERLINED);
    RUST
  }.freeze

  def execute
    pattern = args.first&.downcase

    if pattern.nil? || pattern.empty?
      list_patterns
    elsif PATTERNS.key?(pattern)
      show_pattern(pattern)
    else
      err "Unknown pattern: #{pattern}"
      puts
      list_patterns
    end
  end

  private

  def list_patterns
    section "Example Patterns"

    rows = PATTERNS.map { |name, desc| [name, desc] }
    table(%w[Pattern Description], rows)

    puts
    info "Usage: /ratatui:example <pattern>"
  end

  def show_pattern(name)
    section "#{name} pattern"
    info PATTERNS[name]
    puts
    puts "```rust"
    puts EXAMPLES[name]
    puts "```"
  end
end

RatatuiExample.run
