#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiSnippet < Claude::Generator
  METADATA = { name: "ratatui:snippet", desc: "Common code snippets" }.freeze

  SNIPPETS = {
    "keybindings" => {
      desc: "Help bar showing keyboard shortcuts",
      code: <<~'RUBY'
        def render_keybindings(frame, tui, area)
          bindings = [
            ["q", "Quit"],
            ["↑/k", "Up"],
            ["↓/j", "Down"],
            ["Enter", "Select"],
            ["?", "Help"]
          ]

          text = bindings.map { |key, desc| "#{key}: #{desc}" }.join("  │  ")

          frame.render_widget(
            tui.paragraph(
              text: " #{text} ",
              style: tui.style(fg: :dark_gray)
            ),
            area
          )
        end
      RUBY
    },
    "statusbar" => {
      desc: "Bottom status bar with sections",
      code: <<~'RUBY'
        def render_statusbar(frame, tui, area)
          cols = tui.layout_split(area, direction: :horizontal, constraints: [
            tui.constraint_fill(1),
            tui.constraint_length(20),
            tui.constraint_length(12)
          ])

          # Left: mode/status
          frame.render_widget(
            tui.paragraph(text: " #{@mode.upcase} ", style: tui.style(fg: :black, bg: :blue)),
            cols[0]
          )

          # Center: file/context
          frame.render_widget(
            tui.paragraph(text: @current_file, alignment: :center),
            cols[1]
          )

          # Right: position/time
          frame.render_widget(
            tui.paragraph(text: Time.now.strftime("%H:%M:%S "), alignment: :right),
            cols[2]
          )
        end
      RUBY
    },
    "spinner" => {
      desc: "Animated loading indicator",
      code: <<~'RUBY'
        class Spinner
          FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
          # Alt: %w[◴ ◷ ◶ ◵] or %w[◐ ◓ ◑ ◒] or %w[⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷]

          def initialize
            @frame = 0
            @last_tick = Time.now
          end

          def tick
            if Time.now - @last_tick > 0.1
              @frame = (@frame + 1) % FRAMES.size
              @last_tick = Time.now
            end
          end

          def to_s
            FRAMES[@frame]
          end
        end

        # Usage in render:
        @spinner ||= Spinner.new
        @spinner.tick
        text = "#{@spinner} Loading..."
      RUBY
    },
    "confirm" => {
      desc: "Yes/No confirmation dialog",
      code: <<~'RUBY'
        def render_confirm_dialog(frame, tui, message)
          # Center the dialog
          width = [message.length + 4, 40].max
          height = 5
          x = (frame.area.width - width) / 2
          y = (frame.area.height - height) / 2

          area = tui.rect(x: x, y: y, width: width, height: height)

          # Clear background
          frame.render_widget(RatatuiRuby::Widgets::Clear.new, area)

          # Dialog box
          frame.render_widget(
            tui.paragraph(
              text: "#{message}\n\n[Y]es  [N]o",
              alignment: :center,
              block: tui.block(title: "Confirm", borders: [:all], border_type: :rounded)
            ),
            area
          )
        end

        # Handle in event loop:
        # in { type: :key, code: "y" } then @confirmed = true
        # in { type: :key, code: "n" } then @confirmed = false
      RUBY
    },
    "input" => {
      desc: "Text input field handling",
      code: <<~'RUBY'
        class TextInput
          attr_reader :value, :cursor

          def initialize(value = "")
            @value = value
            @cursor = value.length
          end

          def handle_key(event)
            case event
            in { code: "backspace" }
              delete_back
            in { code: "delete" }
              delete_forward
            in { code: "left" }
              @cursor = [@cursor - 1, 0].max
            in { code: "right" }
              @cursor = [@cursor + 1, @value.length].min
            in { code: "home" }
              @cursor = 0
            in { code: "end" }
              @cursor = @value.length
            in { code: c } if c.is_a?(String) && c.length == 1
              insert(c)
            else
              nil
            end
          end

          def insert(char)
            @value = @value[0...@cursor] + char + @value[@cursor..]
            @cursor += 1
          end

          def delete_back
            return if @cursor == 0
            @value = @value[0...(@cursor - 1)] + @value[@cursor..]
            @cursor -= 1
          end

          def delete_forward
            return if @cursor >= @value.length
            @value = @value[0...@cursor] + @value[(@cursor + 1)..]
          end

          def render_text
            before = @value[0...@cursor]
            cursor_char = @value[@cursor] || " "
            after = @value[(@cursor + 1)..]
            "#{before}\e[7m#{cursor_char}\e[0m#{after}"
          end
        end
      RUBY
    },
    "popup" => {
      desc: "Centered popup/modal pattern",
      code: <<~'RUBY'
        def render_popup(frame, tui, title:, content:, width_pct: 60, height_pct: 40)
          # Calculate centered area
          w = (frame.area.width * width_pct / 100).to_i
          h = (frame.area.height * height_pct / 100).to_i
          x = (frame.area.width - w) / 2
          y = (frame.area.height - h) / 2

          popup_area = tui.rect(x: x, y: y, width: w, height: h)

          # Clear background (optional: dim effect)
          frame.render_widget(RatatuiRuby::Widgets::Clear.new, popup_area)

          # Render popup
          frame.render_widget(
            tui.paragraph(
              text: content,
              wrap: true,
              block: tui.block(
                title: title,
                borders: [:all],
                border_type: :rounded,
                border_style: tui.style(fg: :cyan)
              )
            ),
            popup_area
          )
        end
      RUBY
    },
    "breadcrumb" => {
      desc: "Navigation breadcrumbs",
      code: <<~'RUBY'
        def render_breadcrumbs(frame, tui, area, path)
          parts = path.is_a?(Array) ? path : path.split("/").reject(&:empty?)

          spans = parts.flat_map.with_index do |part, i|
            sep = i > 0 ? [RatatuiRuby::Text::Span.new(content: " › ", style: tui.style(fg: :dark_gray))] : []
            style = i == parts.length - 1 ? tui.style(fg: :white, modifiers: [:bold]) : tui.style(fg: :cyan)
            sep + [RatatuiRuby::Text::Span.new(content: part, style: style)]
          end

          frame.render_widget(
            tui.paragraph(text: RatatuiRuby::Text::Line.new(spans: spans)),
            area
          )
        end

        # Usage:
        # render_breadcrumbs(frame, tui, header_area, ["Home", "Projects", "MyApp"])
      RUBY
    },
    "timer" => {
      desc: "Periodic refresh without blocking",
      code: <<~'RUBY'
        class RefreshTimer
          def initialize(interval_seconds)
            @interval = interval_seconds
            @last_refresh = Time.now - @interval  # Trigger immediately
          end

          def due?
            Time.now - @last_refresh >= @interval
          end

          def reset!
            @last_refresh = Time.now
          end

          def check_and_reset!
            if due?
              reset!
              true
            else
              false
            end
          end
        end

        # Usage:
        @refresh_timer = RefreshTimer.new(5.0)  # Every 5 seconds

        # In event loop:
        if @refresh_timer.check_and_reset!
          @data = fetch_latest_data
        end

        # Use short poll timeout for responsive UI:
        event = tui.poll_event(timeout: 0.1)
      RUBY
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
    puts snippet[:code]
  end
end

RatatuiSnippet.run
