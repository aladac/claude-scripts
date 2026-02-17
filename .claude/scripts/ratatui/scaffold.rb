#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiScaffold < Claude::Generator
  METADATA = { name: "ratatui:scaffold", desc: "Scaffold TUI app" }.freeze

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
    class_name = name.split("_").map(&:capitalize).join
    content = send("template_#{template}", name, class_name)

    # Determine output path
    bin_dir = File.join(Dir.pwd, "bin")
    if Dir.exist?(bin_dir)
      path = File.join(bin_dir, name)
    else
      path = File.join(Dir.pwd, "#{name}.rb")
    end

    section "Generating #{template} scaffold"

    if File.exist?(path)
      err "File already exists: #{path}"
      return
    end

    File.write(path, content)
    File.chmod(0o755, path) if path.end_with?(name) # bin/ scripts

    ok "Created: #{home_path(path)}"
    info "Template: #{template}"
    info "Class: #{class_name}"
  end

  def template_basic(name, class_name)
    <<~RUBY
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      require "ratatui_ruby"

      class #{class_name}
        def initialize
          @running = true
        end

        def run
          RatatuiRuby.run do |tui|
            while @running
              tui.draw { |frame| render(frame, tui) }
              handle_event(tui.poll_event)
            end
          end
        end

        private

        def render(frame, tui)
          frame.render_widget(
            tui.paragraph(
              text: "Hello, RatatuiRuby! Press 'q' to quit.",
              alignment: :center,
              block: tui.block(title: "#{class_name}", borders: [:all])
            ),
            frame.area
          )
        end

        def handle_event(event)
          case event
          in { type: :key, code: "q" } | { type: :key, code: "c", modifiers: ["ctrl"] }
            @running = false
          else
            nil
          end
        end
      end

      #{class_name}.new.run if __FILE__ == $PROGRAM_NAME
    RUBY
  end

  def template_list(name, class_name)
    <<~RUBY
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      require "ratatui_ruby"

      class #{class_name}
        def initialize
          @items = %w[Item1 Item2 Item3 Item4 Item5]
          @list_state = RatatuiRuby::State::ListState.new
          @list_state.select(0)
          @running = true
        end

        def run
          RatatuiRuby.run do |tui|
            while @running
              tui.draw { |frame| render(frame, tui) }
              handle_event(tui.poll_event)
            end
          end
        end

        private

        def render(frame, tui)
          list = tui.list(
            items: @items,
            highlight_style: tui.style(modifiers: [:reversed]),
            highlight_symbol: ">> ",
            block: tui.block(title: "Select Item [j/k/Enter/q]", borders: [:all])
          )
          frame.render_stateful_widget(list, frame.area, @list_state)
        end

        def handle_event(event)
          case event
          in { type: :key, code: "q" }
            @running = false
          in { type: :key, code: "up" | "k" }
            @list_state.select_previous
          in { type: :key, code: "down" | "j" }
            @list_state.select_next
          in { type: :key, code: "enter" }
            handle_selection(@list_state.selected)
          else
            nil
          end
        end

        def handle_selection(index)
          return unless index
          # TODO: Handle selection
        end
      end

      #{class_name}.new.run if __FILE__ == $PROGRAM_NAME
    RUBY
  end

  def template_dashboard(name, class_name)
    <<~RUBY
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      require "ratatui_ruby"

      class #{class_name}
        def initialize
          @running = true
        end

        def run
          RatatuiRuby.run do |tui|
            while @running
              tui.draw { |frame| render(frame, tui) }
              handle_event(tui.poll_event)
            end
          end
        end

        private

        def render(frame, tui)
          areas = tui.layout_split(frame.area, direction: :vertical, constraints: [
            tui.constraint_length(3),
            tui.constraint_fill(1),
            tui.constraint_length(1)
          ])

          render_header(frame, tui, areas[0])
          render_content(frame, tui, areas[1])
          render_footer(frame, tui, areas[2])
        end

        def render_header(frame, tui, area)
          frame.render_widget(
            tui.paragraph(
              text: "#{class_name}",
              alignment: :center,
              style: tui.style(fg: :cyan, modifiers: [:bold]),
              block: tui.block(borders: [:bottom])
            ),
            area
          )
        end

        def render_content(frame, tui, area)
          cols = tui.layout_split(area, direction: :horizontal, constraints: [
            tui.constraint_length(20),
            tui.constraint_fill(1)
          ])

          frame.render_widget(
            tui.paragraph(text: "Sidebar", block: tui.block(title: "Nav", borders: [:all])),
            cols[0]
          )
          frame.render_widget(
            tui.paragraph(text: "Main content area", block: tui.block(title: "Content", borders: [:all])),
            cols[1]
          )
        end

        def render_footer(frame, tui, area)
          frame.render_widget(
            tui.paragraph(
              text: " q: Quit | Tab: Switch pane ",
              style: tui.style(fg: :dark_gray)
            ),
            area
          )
        end

        def handle_event(event)
          case event
          in { type: :key, code: "q" } | { type: :key, code: "c", modifiers: ["ctrl"] }
            @running = false
          else
            nil
          end
        end
      end

      #{class_name}.new.run if __FILE__ == $PROGRAM_NAME
    RUBY
  end
end

RatatuiScaffold.run
