#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiExample < Claude::Generator
  METADATA = { name: "ratatui:example", desc: "Show example patterns" }.freeze

  PATTERNS = {
    "layout" => "Nested layouts with constraints",
    "events" => "Pattern matching for input",
    "async" => "Background shell commands",
    "stateful" => "Interactive list with state",
    "custom-widget" => "Build your own widget",
    "testing" => "Test with TestHelper",
    "inline" => "CLI tool with inline viewport",
    "mouse" => "Handle mouse events",
    "style" => "Colors and modifiers"
  }.freeze

  EXAMPLES = {
    "layout" => <<~RUBY,
      tui.draw do |frame|
        # Main: sidebar + content
        cols = tui.layout_split(frame.area, direction: :horizontal, constraints: [
          tui.constraint_length(25),
          tui.constraint_fill(1)
        ])

        # Content: header + body + footer
        rows = tui.layout_split(cols[1], direction: :vertical, constraints: [
          tui.constraint_length(3),
          tui.constraint_fill(1),
          tui.constraint_length(1)
        ])

        frame.render_widget(sidebar_widget, cols[0])
        frame.render_widget(header_widget, rows[0])
        frame.render_widget(body_widget, rows[1])
        frame.render_widget(footer_widget, rows[2])
      end
    RUBY

    "events" => <<~RUBY,
      case tui.poll_event
      in { type: :key, code: "q" } | { type: :key, code: "c", modifiers: ["ctrl"] }
        break
      in { type: :key, code: "up" | "k" }
        move_up
      in { type: :key, code: "down" | "j" }
        move_down
      in { type: :key, code: /^[a-z]$/ => char }
        handle_char(char)
      in { type: :resize, width:, height: }
        @size = [width, height]
      in { type: :none }
        # Timeout, no event
      else
        nil
      end
    RUBY

    "async" => <<~RUBY,
      class AsyncTask
        def initialize(command)
          @file = File.join(Dir.tmpdir, "task_\#{object_id}.txt")
          @pid = Process.spawn("\#{command} > \#{@file} 2>&1")
          @loading = true
          @result = nil
        end

        def poll
          return unless @loading
          _pid, status = Process.waitpid2(@pid, Process::WNOHANG)
          if status
            @result = File.read(@file).strip
            @success = status.success?
            @loading = false
          end
        end

        def loading? = @loading
        def success? = @success
        def result = @result
      end

      # Usage
      @task = AsyncTask.new("curl -s https://api.example.com")
      # In event loop: @task.poll
    RUBY

    "stateful" => <<~RUBY,
      @list_state = RatatuiRuby::State::ListState.new
      @list_state.select(0)

      # Render
      list = tui.list(
        items: @items,
        highlight_style: tui.style(modifiers: [:reversed]),
        highlight_symbol: ">> "
      )
      frame.render_stateful_widget(list, area, @list_state)

      # Navigate
      @list_state.select_next
      @list_state.select_previous
      @list_state.select_first
      @list_state.select_last

      # Get selection
      selected_index = @list_state.selected
    RUBY

    "custom-widget" => <<~RUBY,
      class ProgressBar
        def initialize(progress:, style: nil)
          @progress = progress.clamp(0.0, 1.0)
          @style = style || RatatuiRuby::Style::Style.new(fg: :green)
        end

        def render(area)
          filled = (area.width * @progress).round
          bar = "█" * filled + "░" * (area.width - filled)

          [RatatuiRuby::Draw.string(area.x, area.y, bar, @style)]
        end
      end

      # Usage
      frame.render_widget(ProgressBar.new(progress: 0.75), area)
    RUBY

    "testing" => <<~RUBY,
      require "ratatui_ruby/test_helper"

      class MyAppTest < Minitest::Test
        include RatatuiRuby::TestHelper

        def test_renders_title
          with_test_terminal(40, 10) do
            RatatuiRuby.draw { |frame| MyApp.new.render(frame) }
            assert_includes buffer_content[0], "My App"
          end
        end

        def test_handles_quit
          with_test_terminal do
            app = MyApp.new
            inject_event("key", { code: "q" })
            app.handle_event(RatatuiRuby.poll_event)
            refute app.running?
          end
        end
      end
    RUBY

    "inline" => <<~RUBY,
      # Preserves terminal scrollback, ideal for CLI tools
      RatatuiRuby.run(viewport: :inline, height: 5) do |tui|
        3.times do |i|
          tui.draw do |frame|
            frame.render_widget(
              tui.paragraph(text: "Processing... \#{i + 1}/3"),
              frame.area
            )
          end
          sleep 0.5
        end
      end
      # Terminal restored, output preserved above
      puts "Done!"
    RUBY

    "mouse" => <<~RUBY,
      case tui.poll_event
      in { type: :mouse, kind: "down", x:, y:, button: "left" }
        handle_click(x, y)
      in { type: :mouse, kind: "drag", x:, y: }
        handle_drag(x, y)
      in { type: :mouse, kind: "scroll_up" }
        scroll_up
      in { type: :mouse, kind: "scroll_down" }
        scroll_down
      end

      # Or use predicates
      if event.mouse?
        if event.down? && event.button == "left"
          handle_click(event.x, event.y)
        end
      end
    RUBY

    "style" => <<~RUBY
      # Named colors
      Style.new(fg: :red, bg: :black)
      Style.new(fg: :light_blue, bg: :dark_gray)

      # Available: :black, :red, :green, :yellow, :blue, :magenta, :cyan, :gray, :white
      #            :dark_gray, :light_red, :light_green, :light_yellow, :light_blue, :light_magenta, :light_cyan

      # Hex colors
      Style.new(fg: "#ff5500", bg: "#1a1a1a")

      # 256-color palette
      Style.new(fg: 196, bg: 232)

      # Modifiers
      Style.new(modifiers: [:bold, :italic, :underlined, :reversed, :dim])

      # Combined
      Style.new(fg: :green, bg: :black, modifiers: [:bold, :underlined])
    RUBY
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
    puts EXAMPLES[name]
  end
end

RatatuiExample.run
