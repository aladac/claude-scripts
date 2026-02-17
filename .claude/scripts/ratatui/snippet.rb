#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiSnippet < Claude::Generator
  METADATA = { name: "ratatui:snippet", desc: "Common code snippets" }.freeze

  SNIPPETS = {
    "keybindings" => {
      desc: "Help bar showing keyboard shortcuts",
      code: <<~'RUST'
        use ratatui::{
            layout::Rect,
            style::{Color, Style},
            widgets::Paragraph,
            Frame,
        };

        fn render_keybindings(frame: &mut Frame, area: Rect) {
            let bindings = [
                ("q", "Quit"),
                ("↑/k", "Up"),
                ("↓/j", "Down"),
                ("Enter", "Select"),
                ("?", "Help"),
            ];

            let text = bindings
                .iter()
                .map(|(key, desc)| format!("{}: {}", key, desc))
                .collect::<Vec<_>>()
                .join("  │  ");

            frame.render_widget(
                Paragraph::new(format!(" {} ", text))
                    .style(Style::new().fg(Color::DarkGray)),
                area,
            );
        }
      RUST
    },
    "statusbar" => {
      desc: "Bottom status bar with sections",
      code: <<~'RUST'
        use ratatui::{
            layout::{Alignment, Constraint, Layout, Rect},
            style::{Color, Style, Stylize},
            widgets::Paragraph,
            Frame,
        };

        fn render_statusbar(frame: &mut Frame, area: Rect, mode: &str, current_file: &str) {
            let [left, center, right] = Layout::horizontal([
                Constraint::Fill(1),
                Constraint::Length(20),
                Constraint::Length(12),
            ]).areas(area);

            // Left: mode/status
            frame.render_widget(
                Paragraph::new(format!(" {} ", mode.to_uppercase()))
                    .style(Style::new().fg(Color::Black).bg(Color::Blue)),
                left,
            );

            // Center: file/context
            frame.render_widget(
                Paragraph::new(current_file).alignment(Alignment::Center),
                center,
            );

            // Right: position/time
            let time = chrono::Local::now().format("%H:%M:%S").to_string();
            frame.render_widget(
                Paragraph::new(format!("{} ", time)).alignment(Alignment::Right),
                right,
            );
        }
      RUST
    },
    "spinner" => {
      desc: "Animated loading indicator",
      code: <<~'RUST'
        use std::time::{Duration, Instant};

        struct Spinner {
            frames: Vec<char>,
            current: usize,
            last_tick: Instant,
            interval: Duration,
        }

        impl Spinner {
            const DOTS: &'static [char] = &['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
            // Alt: ['◴', '◷', '◶', '◵'] or ['◐', '◓', '◑', '◒']

            fn new() -> Self {
                Self {
                    frames: Self::DOTS.to_vec(),
                    current: 0,
                    last_tick: Instant::now(),
                    interval: Duration::from_millis(100),
                }
            }

            fn tick(&mut self) {
                if self.last_tick.elapsed() >= self.interval {
                    self.current = (self.current + 1) % self.frames.len();
                    self.last_tick = Instant::now();
                }
            }

            fn frame(&self) -> char {
                self.frames[self.current]
            }
        }

        // Usage in render:
        // spinner.tick();
        // let text = format!("{} Loading...", spinner.frame());
      RUST
    },
    "confirm" => {
      desc: "Yes/No confirmation dialog",
      code: <<~'RUST'
        use ratatui::{
            layout::{Alignment, Rect},
            style::{Color, Style},
            widgets::{Block, BorderType, Clear, Paragraph},
            Frame,
        };

        fn render_confirm_dialog(frame: &mut Frame, message: &str) {
            let width = message.len().max(40) as u16 + 4;
            let height = 5;
            let x = (frame.area().width.saturating_sub(width)) / 2;
            let y = (frame.area().height.saturating_sub(height)) / 2;

            let area = Rect::new(x, y, width, height);

            // Clear background
            frame.render_widget(Clear, area);

            // Dialog box
            let text = format!("{}\n\n[Y]es  [N]o", message);
            frame.render_widget(
                Paragraph::new(text)
                    .alignment(Alignment::Center)
                    .block(
                        Block::bordered()
                            .title("Confirm")
                            .border_type(BorderType::Rounded)
                    ),
                area,
            );
        }

        // Handle in event loop:
        // KeyCode::Char('y') => confirmed = true,
        // KeyCode::Char('n') => confirmed = false,
      RUST
    },
    "input" => {
      desc: "Text input field handling",
      code: <<~'RUST'
        struct TextInput {
            value: String,
            cursor: usize,
        }

        impl TextInput {
            fn new() -> Self {
                Self {
                    value: String::new(),
                    cursor: 0,
                }
            }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Char(c) => self.insert(c),
                    KeyCode::Backspace => self.delete_back(),
                    KeyCode::Delete => self.delete_forward(),
                    KeyCode::Left => self.cursor = self.cursor.saturating_sub(1),
                    KeyCode::Right => self.cursor = (self.cursor + 1).min(self.value.len()),
                    KeyCode::Home => self.cursor = 0,
                    KeyCode::End => self.cursor = self.value.len(),
                    _ => {}
                }
            }

            fn insert(&mut self, c: char) {
                self.value.insert(self.cursor, c);
                self.cursor += 1;
            }

            fn delete_back(&mut self) {
                if self.cursor > 0 {
                    self.cursor -= 1;
                    self.value.remove(self.cursor);
                }
            }

            fn delete_forward(&mut self) {
                if self.cursor < self.value.len() {
                    self.value.remove(self.cursor);
                }
            }

            fn render(&self) -> String {
                let before = &self.value[..self.cursor];
                let cursor_char = self.value.chars().nth(self.cursor).unwrap_or(' ');
                let after = if self.cursor < self.value.len() {
                    &self.value[self.cursor + 1..]
                } else {
                    ""
                };
                format!("{}\x1b[7m{}\x1b[0m{}", before, cursor_char, after)
            }
        }
      RUST
    },
    "popup" => {
      desc: "Centered popup/modal pattern",
      code: <<~'RUST'
        use ratatui::{
            layout::Rect,
            style::{Color, Style},
            widgets::{Block, BorderType, Clear, Paragraph, Wrap},
            Frame,
        };

        fn render_popup(
            frame: &mut Frame,
            title: &str,
            content: &str,
            width_pct: u16,
            height_pct: u16,
        ) {
            let area = frame.area();
            let w = area.width * width_pct / 100;
            let h = area.height * height_pct / 100;
            let x = (area.width.saturating_sub(w)) / 2;
            let y = (area.height.saturating_sub(h)) / 2;

            let popup_area = Rect::new(x, y, w, h);

            // Clear background
            frame.render_widget(Clear, popup_area);

            // Render popup
            frame.render_widget(
                Paragraph::new(content)
                    .wrap(Wrap { trim: true })
                    .block(
                        Block::bordered()
                            .title(title)
                            .border_type(BorderType::Rounded)
                            .border_style(Style::new().fg(Color::Cyan))
                    ),
                popup_area,
            );
        }
      RUST
    },
    "breadcrumb" => {
      desc: "Navigation breadcrumbs",
      code: <<~'RUST'
        use ratatui::{
            layout::Rect,
            style::{Color, Modifier, Style},
            text::{Line, Span},
            widgets::Paragraph,
            Frame,
        };

        fn render_breadcrumbs(frame: &mut Frame, area: Rect, path: &[&str]) {
            let mut spans = Vec::new();

            for (i, part) in path.iter().enumerate() {
                if i > 0 {
                    spans.push(Span::styled(
                        " › ",
                        Style::new().fg(Color::DarkGray),
                    ));
                }

                let style = if i == path.len() - 1 {
                    Style::new().fg(Color::White).add_modifier(Modifier::BOLD)
                } else {
                    Style::new().fg(Color::Cyan)
                };

                spans.push(Span::styled(*part, style));
            }

            frame.render_widget(Paragraph::new(Line::from(spans)), area);
        }

        // Usage:
        // render_breadcrumbs(frame, header_area, &["Home", "Projects", "MyApp"]);
      RUST
    },
    "timer" => {
      desc: "Periodic refresh without blocking",
      code: <<~'RUST'
        use std::time::{Duration, Instant};

        struct RefreshTimer {
            interval: Duration,
            last_refresh: Instant,
        }

        impl RefreshTimer {
            fn new(interval_secs: f64) -> Self {
                Self {
                    interval: Duration::from_secs_f64(interval_secs),
                    // Trigger immediately on first check
                    last_refresh: Instant::now() - Duration::from_secs_f64(interval_secs),
                }
            }

            fn is_due(&self) -> bool {
                self.last_refresh.elapsed() >= self.interval
            }

            fn reset(&mut self) {
                self.last_refresh = Instant::now();
            }

            fn check_and_reset(&mut self) -> bool {
                if self.is_due() {
                    self.reset();
                    true
                } else {
                    false
                }
            }
        }

        // Usage:
        // let mut refresh_timer = RefreshTimer::new(5.0);  // Every 5 seconds
        //
        // // In event loop:
        // if refresh_timer.check_and_reset() {
        //     data = fetch_latest_data();
        // }
        //
        // // Use short poll timeout for responsive UI:
        // if event::poll(Duration::from_millis(100))? {
        //     // handle event
        // }
      RUST
    }
  }.freeze

  def execute
    name = args.first&.downcase

    if name.nil? || name.empty?
      list_snippets
    elsif SNIPPETS.key?(name)
      show_snippet(name)
    else
      err "Unknown snippet: #{name}"
      puts
      list_snippets
    end
  end

  private

  def list_snippets
    section "Code Snippets"

    rows = SNIPPETS.map { |name, info| [name, info[:desc]] }
    table(%w[Snippet Description], rows)

    puts
    info "Usage: /ratatui:snippet <name>"
  end

  def show_snippet(name)
    snippet = SNIPPETS[name]
    section name
    info snippet[:desc]
    puts
    puts "```rust"
    puts snippet[:code]
    puts "```"
  end
end

RatatuiSnippet.run
