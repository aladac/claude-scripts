#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiComponent < Claude::Generator
  METADATA = { name: "ratatui:component", desc: "Reusable TUI components" }.freeze

  COMPONENTS = {
    "searchable_list" => {
      desc: "List with fuzzy filtering",
      code: <<~'RUBY'
        class SearchableList
          attr_reader :query, :selected

          def initialize(items)
            @all_items = items
            @query = ""
            @list_state = RatatuiRuby::State::ListState.new
            @list_state.select(0)
          end

          def filtered_items
            return @all_items if @query.empty?
            pattern = @query.chars.join(".*")
            @all_items.select { |item| item.to_s.match?(/#{pattern}/i) }
          end

          def handle_event(event)
            case event
            in { type: :key, code: "up" | "k" }
              @list_state.select_previous
            in { type: :key, code: "down" | "j" }
              @list_state.select_next
            in { type: :key, code: "backspace" }
              @query = @query[0..-2]
              @list_state.select_first
            in { type: :key, code: c } if c.is_a?(String) && c.match?(/^[a-zA-Z0-9 ]$/)
              @query += c
              @list_state.select_first
            else
              nil
            end
          end

          def selected_item
            items = filtered_items
            idx = @list_state.selected || 0
            items[idx] if idx < items.size
          end

          def render(frame, tui, area)
            items = filtered_items

            # Split: search bar + list
            areas = tui.layout_split(area, direction: :vertical, constraints: [
              tui.constraint_length(3),
              tui.constraint_fill(1)
            ])

            # Search bar
            search_text = @query.empty? ? "Type to filter..." : @query
            search_style = @query.empty? ? tui.style(fg: :dark_gray) : tui.style(fg: :white)
            frame.render_widget(
              tui.paragraph(
                text: "🔍 #{search_text}",
                style: search_style,
                block: tui.block(borders: [:all])
              ),
              areas[0]
            )

            # List
            list = tui.list(
              items: items,
              highlight_style: tui.style(modifiers: [:reversed]),
              highlight_symbol: "› ",
              block: tui.block(title: "#{items.size} items", borders: [:all])
            )
            frame.render_stateful_widget(list, areas[1], @list_state)
          end
        end

        # Usage:
        @search_list = SearchableList.new(%w[Apple Banana Cherry Date Elderberry])

        # In event loop:
        @search_list.handle_event(event)
        @search_list.render(frame, tui, area)

        # On Enter:
        selected = @search_list.selected_item
      RUBY
    },
    "file_tree" => {
      desc: "Directory tree browser",
      code: <<~'RUBY'
        class FileTree
          Node = Data.define(:path, :name, :directory?, :depth, :expanded)

          def initialize(root)
            @root = File.expand_path(root)
            @expanded = Set.new([@root])
            @list_state = RatatuiRuby::State::ListState.new
            @list_state.select(0)
          end

          def nodes
            build_tree(@root, 0)
          end

          def build_tree(dir, depth)
            result = []
            entries = Dir.entries(dir).reject { |e| e.start_with?(".") }.sort
            entries.each do |name|
              path = File.join(dir, name)
              is_dir = File.directory?(path)
              result << Node.new(
                path: path,
                name: name,
                directory?: is_dir,
                depth: depth,
                expanded: @expanded.include?(path)
              )
              if is_dir && @expanded.include?(path)
                result.concat(build_tree(path, depth + 1))
              end
            end
            result
          rescue Errno::EACCES
            result
          end

          def handle_event(event)
            case event
            in { type: :key, code: "up" | "k" }
              @list_state.select_previous
            in { type: :key, code: "down" | "j" }
              @list_state.select_next
            in { type: :key, code: "enter" | "right" | "l" }
              toggle_expand
            in { type: :key, code: "left" | "h" }
              collapse_current
            else
              nil
            end
          end

          def toggle_expand
            node = selected_node
            return unless node&.directory?
            if @expanded.include?(node.path)
              @expanded.delete(node.path)
            else
              @expanded.add(node.path)
            end
          end

          def collapse_current
            node = selected_node
            return unless node
            @expanded.delete(node.path) if node.directory?
          end

          def selected_node
            nodes[@list_state.selected || 0]
          end

          def render(frame, tui, area)
            items = nodes.map do |node|
              indent = "  " * node.depth
              icon = node.directory? ? (node.expanded ? "📂" : "📁") : "📄"
              "#{indent}#{icon} #{node.name}"
            end

            list = tui.list(
              items: items,
              highlight_style: tui.style(modifiers: [:reversed]),
              block: tui.block(title: @root, borders: [:all])
            )
            frame.render_stateful_widget(list, area, @list_state)
          end
        end
      RUBY
    },
    "log_viewer" => {
      desc: "Scrolling log with auto-follow",
      code: <<~'RUBY'
        class LogViewer
          MAX_LINES = 1000

          def initialize
            @lines = []
            @auto_scroll = true
            @scroll_offset = 0
          end

          def add(line, level: :info)
            timestamp = Time.now.strftime("%H:%M:%S")
            @lines << { time: timestamp, level: level, text: line }
            @lines.shift if @lines.size > MAX_LINES
            @scroll_offset = [@lines.size - 1, 0].max if @auto_scroll
          end

          def info(line)  = add(line, level: :info)
          def warn(line)  = add(line, level: :warn)
          def error(line) = add(line, level: :error)
          def debug(line) = add(line, level: :debug)

          def handle_event(event)
            case event
            in { type: :key, code: "up" | "k" }
              @scroll_offset = [@scroll_offset - 1, 0].max
              @auto_scroll = false
            in { type: :key, code: "down" | "j" }
              @scroll_offset = [@scroll_offset + 1, @lines.size - 1].min
            in { type: :key, code: "g" }
              @scroll_offset = 0
              @auto_scroll = false
            in { type: :key, code: "G" }
              @scroll_offset = [@lines.size - 1, 0].max
              @auto_scroll = true
            in { type: :key, code: "f" }
              @auto_scroll = !@auto_scroll
            else
              nil
            end
          end

          def render(frame, tui, area)
            height = area.height - 2  # Account for borders
            start_idx = [@scroll_offset - height + 1, 0].max
            visible = @lines[start_idx, height] || []

            content = visible.map do |entry|
              color = { info: :white, warn: :yellow, error: :red, debug: :dark_gray }[entry[:level]]
              "[#{entry[:time]}] #{entry[:text]}"
            end.join("\n")

            follow_indicator = @auto_scroll ? " [FOLLOW]" : ""
            title = "Logs (#{@lines.size} lines)#{follow_indicator}"

            frame.render_widget(
              tui.paragraph(
                text: content,
                block: tui.block(title: title, borders: [:all])
              ),
              area
            )
          end
        end
      RUBY
    },
    "tab_view" => {
      desc: "Tabbed container with content",
      code: <<~'RUBY'
        class TabView
          def initialize(tabs)
            @tabs = tabs  # [{ title: "Tab1", content: -> (frame, tui, area) { ... } }, ...]
            @selected = 0
          end

          def handle_event(event)
            case event
            in { type: :key, code: "tab" }
              @selected = (@selected + 1) % @tabs.size
            in { type: :key, code: "shift_tab" | "backtab" }
              @selected = (@selected - 1) % @tabs.size
            in { type: :key, code: n } if n.match?(/^[1-9]$/) && n.to_i <= @tabs.size
              @selected = n.to_i - 1
            else
              nil
            end
          end

          def render(frame, tui, area)
            areas = tui.layout_split(area, direction: :vertical, constraints: [
              tui.constraint_length(3),
              tui.constraint_fill(1)
            ])

            # Tab bar
            frame.render_widget(
              tui.tabs(
                titles: @tabs.map { |t| t[:title] },
                selected: @selected,
                highlight_style: tui.style(fg: :yellow, modifiers: [:bold]),
                divider: " │ ",
                block: tui.block(borders: [:bottom])
              ),
              areas[0]
            )

            # Content
            content_renderer = @tabs[@selected][:content]
            content_renderer.call(frame, tui, areas[1])
          end
        end

        # Usage:
        @tabs = TabView.new([
          { title: "Overview", content: ->(f, t, a) { render_overview(f, t, a) } },
          { title: "Details",  content: ->(f, t, a) { render_details(f, t, a) } },
          { title: "Logs",     content: ->(f, t, a) { render_logs(f, t, a) } }
        ])
      RUBY
    },
    "split_pane" => {
      desc: "Resizable split panes",
      code: <<~'RUBY'
        class SplitPane
          attr_accessor :ratio

          def initialize(direction: :horizontal, ratio: 0.5, min_size: 5)
            @direction = direction
            @ratio = ratio
            @min_size = min_size
            @focused = :left  # or :right / :top / :bottom
          end

          def handle_event(event)
            case event
            in { type: :key, code: "+" | "=" }
              @ratio = [@ratio + 0.05, 0.9].min
            in { type: :key, code: "-" | "_" }
              @ratio = [@ratio - 0.05, 0.1].max
            in { type: :key, code: "tab" }
              @focused = @focused == :left ? :right : :left
            else
              nil
            end
          end

          def areas(parent_area, tui)
            if @direction == :horizontal
              left_width = (parent_area.width * @ratio).to_i
              left_width = [@min_size, left_width, parent_area.width - @min_size].sort[1]

              tui.layout_split(parent_area, direction: :horizontal, constraints: [
                tui.constraint_length(left_width),
                tui.constraint_fill(1)
              ])
            else
              top_height = (parent_area.height * @ratio).to_i
              top_height = [@min_size, top_height, parent_area.height - @min_size].sort[1]

              tui.layout_split(parent_area, direction: :vertical, constraints: [
                tui.constraint_length(top_height),
                tui.constraint_fill(1)
              ])
            end
          end

          def focused?(pane)
            pane == @focused
          end
        end

        # Usage:
        @split = SplitPane.new(direction: :horizontal, ratio: 0.3)
        left_area, right_area = @split.areas(frame.area, tui)

        # Style focused pane differently
        left_style = @split.focused?(:left) ? tui.style(fg: :cyan) : tui.style(fg: :dark_gray)
      RUBY
    },
    "command_palette" => {
      desc: "Ctrl+P style command picker",
      code: <<~'RUBY'
        class CommandPalette
          Command = Data.define(:name, :description, :action)

          def initialize(commands)
            @commands = commands
            @query = ""
            @visible = false
            @list_state = RatatuiRuby::State::ListState.new
          end

          def show!
            @visible = true
            @query = ""
            @list_state.select(0)
          end

          def hide!
            @visible = false
          end

          def visible?
            @visible
          end

          def filtered_commands
            return @commands if @query.empty?
            pattern = @query.chars.join(".*")
            @commands.select { |c| c.name.match?(/#{pattern}/i) || c.description.match?(/#{pattern}/i) }
          end

          def handle_event(event)
            return false unless @visible

            case event
            in { type: :key, code: "escape" }
              hide!
            in { type: :key, code: "enter" }
              execute_selected
              hide!
            in { type: :key, code: "up" }
              @list_state.select_previous
            in { type: :key, code: "down" }
              @list_state.select_next
            in { type: :key, code: "backspace" }
              @query = @query[0..-2]
              @list_state.select_first
            in { type: :key, code: c } if c.is_a?(String) && c.length == 1
              @query += c
              @list_state.select_first
            else
              nil
            end
            true  # Event consumed
          end

          def execute_selected
            cmds = filtered_commands
            idx = @list_state.selected || 0
            cmds[idx]&.action&.call
          end

          def render(frame, tui)
            return unless @visible

            # Center palette
            w = [frame.area.width - 20, 60].min
            h = [filtered_commands.size + 4, 15].min
            x = (frame.area.width - w) / 2
            y = 3

            area = tui.rect(x: x, y: y, width: w, height: h)

            # Clear and draw
            frame.render_widget(RatatuiRuby::Widgets::Clear.new, area)

            areas = tui.layout_split(area, direction: :vertical, constraints: [
              tui.constraint_length(3),
              tui.constraint_fill(1)
            ])

            # Search input
            prompt = @query.empty? ? "Type a command..." : @query
            frame.render_widget(
              tui.paragraph(
                text: "> #{prompt}",
                block: tui.block(borders: [:all], border_style: tui.style(fg: :cyan))
              ),
              areas[0]
            )

            # Command list
            items = filtered_commands.map { |c| "#{c.name}  #{c.description}" }
            list = tui.list(
              items: items,
              highlight_style: tui.style(bg: :blue),
              block: tui.block(borders: [:left, :right, :bottom])
            )
            frame.render_stateful_widget(list, areas[1], @list_state)
          end
        end

        # Usage:
        @palette = CommandPalette.new([
          Command.new(name: "quit", description: "Exit the application", action: -> { @running = false }),
          Command.new(name: "save", description: "Save current file", action: -> { save_file }),
          Command.new(name: "open", description: "Open file", action: -> { open_file_dialog })
        ])

        # Toggle with Ctrl+P:
        # in { type: :key, code: "p", modifiers: ["ctrl"] } then @palette.show!
      RUBY
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
    puts component[:code]
  end
end

RatatuiComponent.run
