#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiComponent < Claude::Generator
  METADATA = { name: "ratatui:component", desc: "Reusable TUI components" }.freeze

  COMPONENTS = {
    "searchable_list" => {
      desc: "List with fuzzy filtering",
      code: <<~'RUST'
        use ratatui::{
            layout::{Constraint, Layout, Rect},
            style::{Color, Style, Stylize},
            widgets::{Block, List, ListItem, ListState, Paragraph},
            Frame,
        };

        struct SearchableList {
            all_items: Vec<String>,
            query: String,
            state: ListState,
        }

        impl SearchableList {
            fn new(items: Vec<String>) -> Self {
                Self {
                    all_items: items,
                    query: String::new(),
                    state: ListState::default().with_selected(Some(0)),
                }
            }

            fn filtered_items(&self) -> Vec<&String> {
                if self.query.is_empty() {
                    self.all_items.iter().collect()
                } else {
                    let query_lower = self.query.to_lowercase();
                    self.all_items
                        .iter()
                        .filter(|item| {
                            let item_lower = item.to_lowercase();
                            // Simple fuzzy: check if all query chars appear in order
                            let mut chars = query_lower.chars().peekable();
                            for c in item_lower.chars() {
                                if chars.peek() == Some(&c) {
                                    chars.next();
                                }
                            }
                            chars.peek().is_none()
                        })
                        .collect()
                }
            }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Up | KeyCode::Char('k') => self.state.select_previous(),
                    KeyCode::Down | KeyCode::Char('j') => self.state.select_next(),
                    KeyCode::Backspace => {
                        self.query.pop();
                        self.state.select_first();
                    }
                    KeyCode::Char(c) if c.is_alphanumeric() || c == ' ' => {
                        self.query.push(c);
                        self.state.select_first();
                    }
                    _ => {}
                }
            }

            fn selected_item(&self) -> Option<&String> {
                let items = self.filtered_items();
                self.state.selected().and_then(|i| items.get(i).copied())
            }

            fn render(&mut self, frame: &mut Frame, area: Rect) {
                let items = self.filtered_items();

                let [search_area, list_area] = Layout::vertical([
                    Constraint::Length(3),
                    Constraint::Fill(1),
                ]).areas(area);

                // Search bar
                let search_text = if self.query.is_empty() {
                    "Type to filter...".to_string()
                } else {
                    self.query.clone()
                };
                let search_style = if self.query.is_empty() {
                    Style::new().fg(Color::DarkGray)
                } else {
                    Style::new().fg(Color::White)
                };

                frame.render_widget(
                    Paragraph::new(format!("🔍 {}", search_text))
                        .style(search_style)
                        .block(Block::bordered()),
                    search_area,
                );

                // List
                let list_items: Vec<ListItem> = items
                    .iter()
                    .map(|i| ListItem::new(i.as_str()))
                    .collect();

                let list = List::new(list_items)
                    .highlight_style(Style::new().reversed())
                    .highlight_symbol("› ")
                    .block(Block::bordered().title(format!("{} items", items.len())));

                frame.render_stateful_widget(list, list_area, &mut self.state);
            }
        }

        // Usage:
        // let mut search_list = SearchableList::new(vec![
        //     "Apple".into(), "Banana".into(), "Cherry".into(),
        // ]);
        // search_list.handle_key(key);
        // search_list.render(frame, area);
        // if let Some(selected) = search_list.selected_item() { ... }
      RUST
    },
    "file_tree" => {
      desc: "Directory tree browser",
      code: <<~'RUST'
        use std::collections::HashSet;
        use std::path::{Path, PathBuf};
        use ratatui::{
            layout::Rect,
            style::{Style, Stylize},
            widgets::{Block, List, ListItem, ListState},
            Frame,
        };

        struct FileNode {
            path: PathBuf,
            name: String,
            is_dir: bool,
            depth: usize,
            expanded: bool,
        }

        struct FileTree {
            root: PathBuf,
            expanded: HashSet<PathBuf>,
            state: ListState,
        }

        impl FileTree {
            fn new(root: impl AsRef<Path>) -> Self {
                let root = root.as_ref().to_path_buf();
                let mut expanded = HashSet::new();
                expanded.insert(root.clone());
                Self {
                    root,
                    expanded,
                    state: ListState::default().with_selected(Some(0)),
                }
            }

            fn build_tree(&self, dir: &Path, depth: usize) -> Vec<FileNode> {
                let mut result = Vec::new();
                let entries = match std::fs::read_dir(dir) {
                    Ok(e) => e,
                    Err(_) => return result,
                };

                let mut entries: Vec<_> = entries
                    .filter_map(|e| e.ok())
                    .filter(|e| !e.file_name().to_string_lossy().starts_with('.'))
                    .collect();
                entries.sort_by_key(|e| e.file_name());

                for entry in entries {
                    let path = entry.path();
                    let is_dir = path.is_dir();
                    let expanded = self.expanded.contains(&path);

                    result.push(FileNode {
                        path: path.clone(),
                        name: entry.file_name().to_string_lossy().into_owned(),
                        is_dir,
                        depth,
                        expanded,
                    });

                    if is_dir && expanded {
                        result.extend(self.build_tree(&path, depth + 1));
                    }
                }
                result
            }

            fn nodes(&self) -> Vec<FileNode> {
                self.build_tree(&self.root, 0)
            }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Up | KeyCode::Char('k') => self.state.select_previous(),
                    KeyCode::Down | KeyCode::Char('j') => self.state.select_next(),
                    KeyCode::Enter | KeyCode::Right | KeyCode::Char('l') => self.toggle_expand(),
                    KeyCode::Left | KeyCode::Char('h') => self.collapse_current(),
                    _ => {}
                }
            }

            fn toggle_expand(&mut self) {
                if let Some(node) = self.selected_node() {
                    if node.is_dir {
                        if self.expanded.contains(&node.path) {
                            self.expanded.remove(&node.path);
                        } else {
                            self.expanded.insert(node.path);
                        }
                    }
                }
            }

            fn collapse_current(&mut self) {
                if let Some(node) = self.selected_node() {
                    if node.is_dir {
                        self.expanded.remove(&node.path);
                    }
                }
            }

            fn selected_node(&self) -> Option<FileNode> {
                let nodes = self.nodes();
                self.state.selected().and_then(|i| nodes.into_iter().nth(i))
            }

            fn render(&mut self, frame: &mut Frame, area: Rect) {
                let nodes = self.nodes();
                let items: Vec<ListItem> = nodes
                    .iter()
                    .map(|node| {
                        let indent = "  ".repeat(node.depth);
                        let icon = if node.is_dir {
                            if node.expanded { "📂" } else { "📁" }
                        } else {
                            "📄"
                        };
                        ListItem::new(format!("{}{} {}", indent, icon, node.name))
                    })
                    .collect();

                let list = List::new(items)
                    .highlight_style(Style::new().reversed())
                    .block(Block::bordered().title(self.root.display().to_string()));

                frame.render_stateful_widget(list, area, &mut self.state);
            }
        }
      RUST
    },
    "log_viewer" => {
      desc: "Scrolling log with auto-follow",
      code: <<~'RUST'
        use ratatui::{
            layout::Rect,
            style::{Color, Style},
            widgets::{Block, Paragraph},
            Frame,
        };

        #[derive(Clone, Copy)]
        enum LogLevel {
            Info,
            Warn,
            Error,
            Debug,
        }

        struct LogEntry {
            time: String,
            level: LogLevel,
            text: String,
        }

        struct LogViewer {
            lines: Vec<LogEntry>,
            auto_scroll: bool,
            scroll_offset: usize,
            max_lines: usize,
        }

        impl LogViewer {
            fn new() -> Self {
                Self {
                    lines: Vec::new(),
                    auto_scroll: true,
                    scroll_offset: 0,
                    max_lines: 1000,
                }
            }

            fn add(&mut self, text: impl Into<String>, level: LogLevel) {
                let time = chrono::Local::now().format("%H:%M:%S").to_string();
                self.lines.push(LogEntry {
                    time,
                    level,
                    text: text.into(),
                });
                if self.lines.len() > self.max_lines {
                    self.lines.remove(0);
                }
                if self.auto_scroll {
                    self.scroll_offset = self.lines.len().saturating_sub(1);
                }
            }

            fn info(&mut self, text: impl Into<String>) { self.add(text, LogLevel::Info); }
            fn warn(&mut self, text: impl Into<String>) { self.add(text, LogLevel::Warn); }
            fn error(&mut self, text: impl Into<String>) { self.add(text, LogLevel::Error); }
            fn debug(&mut self, text: impl Into<String>) { self.add(text, LogLevel::Debug); }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Up | KeyCode::Char('k') => {
                        self.scroll_offset = self.scroll_offset.saturating_sub(1);
                        self.auto_scroll = false;
                    }
                    KeyCode::Down | KeyCode::Char('j') => {
                        self.scroll_offset = (self.scroll_offset + 1).min(self.lines.len().saturating_sub(1));
                    }
                    KeyCode::Char('g') => {
                        self.scroll_offset = 0;
                        self.auto_scroll = false;
                    }
                    KeyCode::Char('G') => {
                        self.scroll_offset = self.lines.len().saturating_sub(1);
                        self.auto_scroll = true;
                    }
                    KeyCode::Char('f') => {
                        self.auto_scroll = !self.auto_scroll;
                    }
                    _ => {}
                }
            }

            fn render(&self, frame: &mut Frame, area: Rect) {
                let height = (area.height as usize).saturating_sub(2);
                let start = self.scroll_offset.saturating_sub(height.saturating_sub(1));
                let visible: Vec<_> = self.lines.iter().skip(start).take(height).collect();

                let content = visible
                    .iter()
                    .map(|e| format!("[{}] {}", e.time, e.text))
                    .collect::<Vec<_>>()
                    .join("\n");

                let follow = if self.auto_scroll { " [FOLLOW]" } else { "" };
                let title = format!("Logs ({} lines){}", self.lines.len(), follow);

                frame.render_widget(
                    Paragraph::new(content)
                        .block(Block::bordered().title(title)),
                    area,
                );
            }
        }
      RUST
    },
    "tab_view" => {
      desc: "Tabbed container with content",
      code: <<~'RUST'
        use ratatui::{
            layout::{Constraint, Layout, Rect},
            style::{Modifier, Style, Stylize},
            widgets::{Block, Borders, Tabs},
            Frame,
        };

        struct Tab<'a> {
            title: &'a str,
            render: fn(&mut Frame, Rect),
        }

        struct TabView<'a> {
            tabs: Vec<Tab<'a>>,
            selected: usize,
        }

        impl<'a> TabView<'a> {
            fn new(tabs: Vec<Tab<'a>>) -> Self {
                Self { tabs, selected: 0 }
            }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Tab => {
                        self.selected = (self.selected + 1) % self.tabs.len();
                    }
                    KeyCode::BackTab => {
                        self.selected = (self.selected + self.tabs.len() - 1) % self.tabs.len();
                    }
                    KeyCode::Char(c) if c.is_ascii_digit() => {
                        let n = c.to_digit(10).unwrap() as usize;
                        if n > 0 && n <= self.tabs.len() {
                            self.selected = n - 1;
                        }
                    }
                    _ => {}
                }
            }

            fn render(&self, frame: &mut Frame, area: Rect) {
                let [tab_area, content_area] = Layout::vertical([
                    Constraint::Length(3),
                    Constraint::Fill(1),
                ]).areas(area);

                // Tab bar
                let titles: Vec<_> = self.tabs.iter().map(|t| t.title).collect();
                frame.render_widget(
                    Tabs::new(titles)
                        .select(self.selected)
                        .highlight_style(Style::new().yellow().bold())
                        .divider(" │ ")
                        .block(Block::default().borders(Borders::BOTTOM)),
                    tab_area,
                );

                // Content
                if let Some(tab) = self.tabs.get(self.selected) {
                    (tab.render)(frame, content_area);
                }
            }
        }

        // Usage:
        // let tabs = TabView::new(vec![
        //     Tab { title: "Overview", render: render_overview },
        //     Tab { title: "Details", render: render_details },
        //     Tab { title: "Logs", render: render_logs },
        // ]);
      RUST
    },
    "split_pane" => {
      desc: "Resizable split panes",
      code: <<~'RUST'
        use ratatui::layout::{Constraint, Direction, Layout, Rect};

        #[derive(Clone, Copy, PartialEq)]
        enum Pane {
            Left,
            Right,
        }

        struct SplitPane {
            direction: Direction,
            ratio: f64,
            min_size: u16,
            focused: Pane,
        }

        impl SplitPane {
            fn horizontal(ratio: f64) -> Self {
                Self {
                    direction: Direction::Horizontal,
                    ratio,
                    min_size: 5,
                    focused: Pane::Left,
                }
            }

            fn vertical(ratio: f64) -> Self {
                Self {
                    direction: Direction::Vertical,
                    ratio,
                    min_size: 5,
                    focused: Pane::Left,
                }
            }

            fn handle_key(&mut self, key: KeyEvent) {
                match key.code {
                    KeyCode::Char('+') | KeyCode::Char('=') => {
                        self.ratio = (self.ratio + 0.05).min(0.9);
                    }
                    KeyCode::Char('-') | KeyCode::Char('_') => {
                        self.ratio = (self.ratio - 0.05).max(0.1);
                    }
                    KeyCode::Tab => {
                        self.focused = if self.focused == Pane::Left {
                            Pane::Right
                        } else {
                            Pane::Left
                        };
                    }
                    _ => {}
                }
            }

            fn areas(&self, parent: Rect) -> [Rect; 2] {
                let size = if self.direction == Direction::Horizontal {
                    let w = (parent.width as f64 * self.ratio) as u16;
                    w.clamp(self.min_size, parent.width - self.min_size)
                } else {
                    let h = (parent.height as f64 * self.ratio) as u16;
                    h.clamp(self.min_size, parent.height - self.min_size)
                };

                Layout::default()
                    .direction(self.direction)
                    .constraints([Constraint::Length(size), Constraint::Fill(1)])
                    .areas(parent)
            }

            fn is_focused(&self, pane: Pane) -> bool {
                self.focused == pane
            }
        }

        // Usage:
        // let mut split = SplitPane::horizontal(0.3);
        // let [left, right] = split.areas(frame.area());
        // let left_style = if split.is_focused(Pane::Left) { ... };
      RUST
    },
    "command_palette" => {
      desc: "Ctrl+P style command picker",
      code: <<~'RUST'
        use ratatui::{
            layout::{Constraint, Layout, Rect},
            style::{Color, Style, Stylize},
            widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph},
            Frame,
        };

        struct Command {
            name: String,
            description: String,
            action: fn(&mut App),
        }

        struct CommandPalette {
            commands: Vec<Command>,
            query: String,
            visible: bool,
            state: ListState,
        }

        impl CommandPalette {
            fn new(commands: Vec<Command>) -> Self {
                Self {
                    commands,
                    query: String::new(),
                    visible: false,
                    state: ListState::default(),
                }
            }

            fn show(&mut self) {
                self.visible = true;
                self.query.clear();
                self.state.select_first();
            }

            fn hide(&mut self) {
                self.visible = false;
            }

            fn is_visible(&self) -> bool {
                self.visible
            }

            fn filtered_commands(&self) -> Vec<&Command> {
                if self.query.is_empty() {
                    self.commands.iter().collect()
                } else {
                    let query = self.query.to_lowercase();
                    self.commands
                        .iter()
                        .filter(|c| {
                            c.name.to_lowercase().contains(&query)
                                || c.description.to_lowercase().contains(&query)
                        })
                        .collect()
                }
            }

            fn handle_key(&mut self, key: KeyEvent) -> Option<fn(&mut App)> {
                if !self.visible {
                    return None;
                }

                match key.code {
                    KeyCode::Esc => self.hide(),
                    KeyCode::Enter => {
                        let cmds = self.filtered_commands();
                        if let Some(cmd) = self.state.selected().and_then(|i| cmds.get(i)) {
                            let action = cmd.action;
                            self.hide();
                            return Some(action);
                        }
                    }
                    KeyCode::Up => self.state.select_previous(),
                    KeyCode::Down => self.state.select_next(),
                    KeyCode::Backspace => {
                        self.query.pop();
                        self.state.select_first();
                    }
                    KeyCode::Char(c) => {
                        self.query.push(c);
                        self.state.select_first();
                    }
                    _ => {}
                }
                None
            }

            fn render(&mut self, frame: &mut Frame) {
                if !self.visible {
                    return;
                }

                let cmds = self.filtered_commands();
                let w = frame.area().width.saturating_sub(20).min(60);
                let h = (cmds.len() + 4).min(15) as u16;
                let x = (frame.area().width.saturating_sub(w)) / 2;
                let y = 3;

                let area = Rect::new(x, y, w, h);

                frame.render_widget(Clear, area);

                let [search_area, list_area] = Layout::vertical([
                    Constraint::Length(3),
                    Constraint::Fill(1),
                ]).areas(area);

                // Search input
                let prompt = if self.query.is_empty() {
                    "Type a command...".to_string()
                } else {
                    self.query.clone()
                };
                frame.render_widget(
                    Paragraph::new(format!("> {}", prompt))
                        .block(Block::bordered().border_style(Style::new().cyan())),
                    search_area,
                );

                // Command list
                let items: Vec<ListItem> = cmds
                    .iter()
                    .map(|c| ListItem::new(format!("{}  {}", c.name, c.description)))
                    .collect();
                let list = List::new(items)
                    .highlight_style(Style::new().bg(Color::Blue))
                    .block(Block::default().borders(Borders::LEFT | Borders::RIGHT | Borders::BOTTOM));

                frame.render_stateful_widget(list, list_area, &mut self.state);
            }
        }

        // Usage:
        // Toggle with Ctrl+P:
        // if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('p') {
        //     palette.show();
        // }
      RUST
    }
  }.freeze

  def execute
    name = args.first&.downcase

    if name.nil? || name.empty?
      list_components
    elsif COMPONENTS.key?(name)
      show_component(name)
    else
      err "Unknown component: #{name}"
      puts
      list_components
    end
  end

  private

  def list_components
    section "Reusable Components"

    rows = COMPONENTS.map { |name, info| [name, info[:desc]] }
    table(%w[Component Description], rows)

    puts
    info "Usage: /ratatui:component <name>"
  end

  def show_component(name)
    component = COMPONENTS[name]
    section name
    info component[:desc]
    puts
    puts "```rust"
    puts component[:code]
    puts "```"
  end
end

RatatuiComponent.run
