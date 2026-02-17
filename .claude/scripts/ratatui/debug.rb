#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiDebug < Claude::Generator
  METADATA = { name: "ratatui:debug", desc: "Debug setup generator" }.freeze

  TEMPLATES = {
    "logging" => {
      desc: "File-based debug logging",
      code: <<~'RUST'
        use std::fs::OpenOptions;
        use std::io::Write;
        use std::sync::Mutex;

        // Global debug logger that doesn't interfere with TUI
        lazy_static::lazy_static! {
            static ref DEBUG_LOG: Mutex<Option<std::fs::File>> = Mutex::new(None);
        }

        pub fn init_debug_log() {
            if std::env::var("DEBUG").is_ok() {
                let file = OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open("/tmp/tui_debug.log")
                    .ok();
                *DEBUG_LOG.lock().unwrap() = file;
            }
        }

        pub fn debug_log(level: &str, msg: &str) {
            if let Some(file) = DEBUG_LOG.lock().unwrap().as_mut() {
                let timestamp = chrono::Local::now().format("%H:%M:%S%.3f");
                let _ = writeln!(file, "[{}] [{}] {}", timestamp, level, msg);
            }
        }

        #[macro_export]
        macro_rules! debug_info {
            ($($arg:tt)*) => {
                debug_log("INFO", &format!($($arg)*));
            };
        }

        #[macro_export]
        macro_rules! debug_error {
            ($($arg:tt)*) => {
                debug_log("ERROR", &format!($($arg)*));
            };
        }

        // Usage:
        // init_debug_log();  // Call once at startup
        //
        // DEBUG=1 cargo run
        // tail -f /tmp/tui_debug.log
        //
        // debug_info!("Application started");
        // debug_info!("Event: {:?}", event);
        // debug_error!("Something went wrong: {}", e);
      RUST
    },
    "fps" => {
      desc: "FPS counter and render timing",
      code: <<~'RUST'
        use std::collections::VecDeque;
        use std::time::{Duration, Instant};

        struct FPSCounter {
            frame_times: VecDeque<Duration>,
            last_frame: Instant,
            sample_size: usize,
        }

        impl FPSCounter {
            fn new(sample_size: usize) -> Self {
                Self {
                    frame_times: VecDeque::with_capacity(sample_size),
                    last_frame: Instant::now(),
                    sample_size,
                }
            }

            fn tick(&mut self) {
                let now = Instant::now();
                let frame_time = now - self.last_frame;
                self.last_frame = now;

                self.frame_times.push_back(frame_time);
                if self.frame_times.len() > self.sample_size {
                    self.frame_times.pop_front();
                }
            }

            fn fps(&self) -> f64 {
                if self.frame_times.is_empty() {
                    return 0.0;
                }
                let avg: Duration = self.frame_times.iter().sum::<Duration>() / self.frame_times.len() as u32;
                1.0 / avg.as_secs_f64()
            }

            fn frame_time_ms(&self) -> f64 {
                self.frame_times.back().map(|d| d.as_secs_f64() * 1000.0).unwrap_or(0.0)
            }

            fn avg_frame_time_ms(&self) -> f64 {
                if self.frame_times.is_empty() {
                    return 0.0;
                }
                let avg: Duration = self.frame_times.iter().sum::<Duration>() / self.frame_times.len() as u32;
                avg.as_secs_f64() * 1000.0
            }

            fn stats(&self) -> String {
                format!(
                    "FPS: {:.1} | Frame: {:.2}ms | Avg: {:.2}ms",
                    self.fps(),
                    self.frame_time_ms(),
                    self.avg_frame_time_ms()
                )
            }
        }

        // Usage in app:
        // let mut fps = FPSCounter::new(60);
        //
        // // In render loop:
        // fps.tick();
        // terminal.draw(|frame| {
        //     // ... render app ...
        //
        //     // Show FPS in corner (debug mode only)
        //     if debug_mode {
        //         let area = Rect::new(frame.area().width - 40, 0, 40, 1);
        //         frame.render_widget(
        //             Paragraph::new(fps.stats()).style(Style::new().dark_gray()),
        //             area,
        //         );
        //     }
        // })?;
      RUST
    },
    "state_inspector" => {
      desc: "Widget to inspect application state",
      code: <<~'RUST'
        use ratatui::{
            layout::Rect,
            style::{Color, Style},
            widgets::{Block, Paragraph},
            Frame,
        };

        trait Inspectable {
            fn inspect(&self) -> Vec<(String, String)>;
        }

        struct StateInspector {
            scroll: usize,
        }

        impl StateInspector {
            fn new() -> Self {
                Self { scroll: 0 }
            }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Up => self.scroll = self.scroll.saturating_sub(1),
                    KeyCode::Down => self.scroll += 1,
                    _ => {}
                }
            }

            fn render<T: Inspectable>(&self, frame: &mut Frame, area: Rect, app: &T) {
                let state_lines = app.inspect();
                let height = (area.height as usize).saturating_sub(2);
                let visible: Vec<_> = state_lines
                    .iter()
                    .skip(self.scroll)
                    .take(height)
                    .collect();

                let content = visible
                    .iter()
                    .map(|(k, v)| format!("{}: {}", k, v))
                    .collect::<Vec<_>>()
                    .join("\n");

                frame.render_widget(
                    Paragraph::new(content)
                        .block(
                            Block::bordered()
                                .title(format!("State Inspector ({} vars)", state_lines.len()))
                                .border_style(Style::new().fg(Color::Yellow))
                        ),
                    area,
                );
            }
        }

        // Implement for your app:
        impl Inspectable for App {
            fn inspect(&self) -> Vec<(String, String)> {
                vec![
                    ("running".into(), format!("{}", self.running)),
                    ("selected".into(), format!("{:?}", self.selected)),
                    ("items".into(), format!("[{} items]", self.items.len())),
                    ("mode".into(), format!("{:?}", self.mode)),
                ]
            }
        }

        // Toggle with F12:
        // if show_inspector {
        //     let area = Rect::new(frame.area().width - 40, 0, 40, frame.area().height);
        //     inspector.render(frame, area, &app);
        // }
      RUST
    },
    "event_logger" => {
      desc: "Log all events for debugging",
      code: <<~'RUST'
        use std::collections::VecDeque;
        use std::time::Instant;
        use ratatui::{
            crossterm::event::{Event, KeyEvent, MouseEvent},
            layout::Rect,
            widgets::{Block, Paragraph},
            Frame,
        };

        struct EventEntry {
            time: Instant,
            description: String,
        }

        struct EventLogger {
            events: VecDeque<EventEntry>,
            max_events: usize,
            start_time: Instant,
        }

        impl EventLogger {
            fn new(max_events: usize) -> Self {
                Self {
                    events: VecDeque::new(),
                    max_events,
                    start_time: Instant::now(),
                }
            }

            fn log(&mut self, event: &Event) {
                let description = match event {
                    Event::Key(KeyEvent { code, modifiers, .. }) => {
                        format!("KEY: {:?} {:?}", code, modifiers)
                    }
                    Event::Mouse(MouseEvent { kind, column, row, .. }) => {
                        format!("MOUSE: {:?} at ({},{})", kind, column, row)
                    }
                    Event::Resize(w, h) => format!("RESIZE: {}x{}", w, h),
                    Event::FocusGained => "FOCUS_GAINED".into(),
                    Event::FocusLost => "FOCUS_LOST".into(),
                    Event::Paste(s) => format!("PASTE: {:?}", s),
                };

                self.events.push_back(EventEntry {
                    time: Instant::now(),
                    description,
                });

                if self.events.len() > self.max_events {
                    self.events.pop_front();
                }
            }

            fn render(&self, frame: &mut Frame, area: Rect) {
                let height = (area.height as usize).saturating_sub(2);
                let lines: Vec<_> = self.events
                    .iter()
                    .rev()
                    .take(height)
                    .map(|e| {
                        let elapsed = e.time.duration_since(self.start_time);
                        format!("[{:.2}s] {}", elapsed.as_secs_f64(), e.description)
                    })
                    .collect();

                frame.render_widget(
                    Paragraph::new(lines.join("\n"))
                        .block(Block::bordered().title("Events")),
                    area,
                );
            }
        }

        // Usage:
        // let mut event_log = EventLogger::new(100);
        //
        // // In event loop:
        // if let Ok(event) = event::read() {
        //     if debug_mode {
        //         event_log.log(&event);
        //     }
        //     // handle event...
        // }
      RUST
    },
    "full" => {
      desc: "Complete debug setup with all helpers",
      code: <<~'RUST'
        // Complete debug module for Ratatui apps
        // Add to Cargo.toml: lazy_static = "1.4", chrono = "0.4"

        use std::collections::VecDeque;
        use std::fs::OpenOptions;
        use std::io::Write;
        use std::sync::Mutex;
        use std::time::{Duration, Instant};

        use ratatui::{
            crossterm::event::Event,
            layout::Rect,
            style::{Color, Style},
            widgets::{Block, Clear, Paragraph},
            Frame,
        };

        lazy_static::lazy_static! {
            static ref DEBUG_LOG: Mutex<Option<std::fs::File>> = Mutex::new(None);
        }

        pub struct DebugState {
            enabled: bool,
            fps_counter: FPSCounter,
            events: VecDeque<String>,
            start_time: Instant,
        }

        impl DebugState {
            pub fn new() -> Self {
                let enabled = std::env::var("DEBUG").is_ok();
                if enabled {
                    let file = OpenOptions::new()
                        .create(true)
                        .truncate(true)
                        .write(true)
                        .open("/tmp/tui_debug.log")
                        .ok();
                    *DEBUG_LOG.lock().unwrap() = file;
                }
                Self {
                    enabled,
                    fps_counter: FPSCounter::new(60),
                    events: VecDeque::new(),
                    start_time: Instant::now(),
                }
            }

            pub fn is_enabled(&self) -> bool {
                self.enabled
            }

            pub fn log(&self, level: &str, msg: &str) {
                if !self.enabled { return; }
                if let Some(file) = DEBUG_LOG.lock().unwrap().as_mut() {
                    let timestamp = chrono::Local::now().format("%H:%M:%S%.3f");
                    let _ = writeln!(file, "[{}] [{}] {}", timestamp, level, msg);
                }
            }

            pub fn tick_fps(&mut self) {
                if self.enabled {
                    self.fps_counter.tick();
                }
            }

            pub fn log_event(&mut self, event: &Event) {
                if !self.enabled { return; }
                let desc = format!("{:?}", event);
                let truncated = if desc.len() > 40 { &desc[..40] } else { &desc };
                self.events.push_back(truncated.to_string());
                if self.events.len() > 10 {
                    self.events.pop_front();
                }
            }

            pub fn render_overlay(&self, frame: &mut Frame) {
                if !self.enabled { return; }

                let mut lines = vec![
                    self.fps_counter.stats(),
                    format!("Events: {}", self.events.len()),
                    String::new(),
                ];

                for event in self.events.iter().rev().take(5) {
                    lines.push(format!("  {}", event));
                }

                let w = 35;
                let h = lines.len() as u16 + 2;
                let area = Rect::new(frame.area().width.saturating_sub(w), 0, w, h);

                frame.render_widget(Clear, area);
                frame.render_widget(
                    Paragraph::new(lines.join("\n"))
                        .block(
                            Block::bordered()
                                .title("[DEBUG]")
                                .border_style(Style::new().fg(Color::Yellow))
                        ),
                    area,
                );
            }
        }

        struct FPSCounter {
            frame_times: VecDeque<Duration>,
            last_frame: Instant,
            sample_size: usize,
        }

        impl FPSCounter {
            fn new(sample_size: usize) -> Self {
                Self {
                    frame_times: VecDeque::with_capacity(sample_size),
                    last_frame: Instant::now(),
                    sample_size,
                }
            }

            fn tick(&mut self) {
                let now = Instant::now();
                self.frame_times.push_back(now - self.last_frame);
                self.last_frame = now;
                if self.frame_times.len() > self.sample_size {
                    self.frame_times.pop_front();
                }
            }

            fn fps(&self) -> f64 {
                if self.frame_times.is_empty() { return 0.0; }
                let avg: Duration = self.frame_times.iter().sum::<Duration>() / self.frame_times.len() as u32;
                1.0 / avg.as_secs_f64()
            }

            fn stats(&self) -> String {
                format!("FPS: {:.1}", self.fps())
            }
        }

        // Usage in your app:
        //
        // struct App {
        //     debug: DebugState,
        //     // ...
        // }
        //
        // impl App {
        //     fn new() -> Self {
        //         Self {
        //             debug: DebugState::new(),
        //             // ...
        //         }
        //     }
        //
        //     fn run(&mut self, terminal: &mut DefaultTerminal) -> std::io::Result<()> {
        //         loop {
        //             self.debug.tick_fps();
        //
        //             terminal.draw(|frame| {
        //                 self.render(frame);
        //                 self.debug.render_overlay(frame);
        //             })?;
        //
        //             if let Event::Key(key) = event::read()? {
        //                 self.debug.log_event(&Event::Key(key));
        //                 // handle key...
        //             }
        //         }
        //     }
        // }
        //
        // Run with: DEBUG=1 cargo run
        // Tail log: tail -f /tmp/tui_debug.log
      RUST
    }
  }.freeze

  def execute
    template = args.first&.downcase

    if template.nil? || template.empty?
      list_templates
    elsif TEMPLATES.key?(template)
      show_template(template)
    else
      err "Unknown template: #{template}"
      puts
      list_templates
    end
  end

  private

  def list_templates
    section "Debug Templates"

    rows = TEMPLATES.map { |name, info| [name, info[:desc]] }
    table(%w[Template Description], rows)

    puts
    info "Usage: /ratatui:debug <template>"
    info "Recommended: /ratatui:debug full"
  end

  def show_template(name)
    template = TEMPLATES[name]
    section name
    info template[:desc]
    puts
    puts "```rust"
    puts template[:code]
    puts "```"
  end
end

RatatuiDebug.run
