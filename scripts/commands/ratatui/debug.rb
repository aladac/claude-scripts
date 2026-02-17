#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiDebug < Claude::Generator
  METADATA = { name: "ratatui:debug", desc: "Debug setup generator" }.freeze

  TEMPLATES = {
    "logging" => {
      desc: "File-based debug logging",
      code: <<~'RUBY'
        # Debug logging that doesn't interfere with TUI
        module Debug
          LOG_FILE = File.join(Dir.tmpdir, "tui_debug.log")
          @enabled = ENV["DEBUG"] == "1"

          class << self
            attr_accessor :enabled

            def log(msg, level: :info)
              return unless @enabled
              timestamp = Time.now.strftime("%H:%M:%S.%L")
              File.open(LOG_FILE, "a") do |f|
                f.puts "[#{timestamp}] [#{level.upcase}] #{msg}"
              end
            end

            def info(msg)  = log(msg, level: :info)
            def warn(msg)  = log(msg, level: :warn)
            def error(msg) = log(msg, level: :error)
            def debug(msg) = log(msg, level: :debug)

            def inspect_object(label, obj)
              log("#{label}: #{obj.inspect}")
            end

            def clear!
              File.write(LOG_FILE, "") if File.exist?(LOG_FILE)
            end

            def path
              LOG_FILE
            end
          end
        end

        # Usage:
        # DEBUG=1 ruby my_app.rb
        # tail -f /tmp/tui_debug.log

        Debug.info "Application started"
        Debug.inspect_object "Event", event
        Debug.error "Something went wrong: #{e.message}"
      RUBY
    },
    "fps" => {
      desc: "FPS counter and render timing",
      code: <<~'RUBY'
        class FPSCounter
          def initialize(sample_size: 60)
            @frame_times = []
            @sample_size = sample_size
            @last_frame = Time.now
          end

          def tick
            now = Time.now
            @frame_times << (now - @last_frame)
            @frame_times.shift if @frame_times.size > @sample_size
            @last_frame = now
          end

          def fps
            return 0 if @frame_times.empty?
            avg_frame_time = @frame_times.sum / @frame_times.size
            (1.0 / avg_frame_time).round(1)
          end

          def frame_time_ms
            return 0 if @frame_times.empty?
            (@frame_times.last * 1000).round(2)
          end

          def avg_frame_time_ms
            return 0 if @frame_times.empty?
            (@frame_times.sum / @frame_times.size * 1000).round(2)
          end

          def render_stats(tui)
            "FPS: #{fps} | Frame: #{frame_time_ms}ms | Avg: #{avg_frame_time_ms}ms"
          end
        end

        # Usage in app:
        @fps = FPSCounter.new

        # In render loop:
        @fps.tick
        tui.draw do |frame|
          # ... render app ...

          # Show FPS in corner (debug mode only)
          if @debug_mode
            frame.render_widget(
              tui.paragraph(text: @fps.render_stats(tui), style: tui.style(fg: :dark_gray)),
              tui.rect(x: frame.area.width - 40, y: 0, width: 40, height: 1)
            )
          end
        end
      RUBY
    },
    "state_inspector" => {
      desc: "Widget to inspect application state",
      code: <<~'RUBY'
        class StateInspector
          def initialize(app)
            @app = app
            @scroll = 0
          end

          def handle_event(event)
            case event
            in { type: :key, code: "up" }
              @scroll = [@scroll - 1, 0].max
            in { type: :key, code: "down" }
              @scroll += 1
            else
              nil
            end
          end

          def state_lines
            vars = @app.instance_variables.map do |var|
              value = @app.instance_variable_get(var)
              formatted = format_value(value)
              "#{var}: #{formatted}"
            end
            vars.sort
          end

          def format_value(val, max_len: 50)
            str = case val
                  when Array then "[#{val.size} items]"
                  when Hash then "{#{val.size} keys}"
                  when String then val.length > max_len ? "#{val[0..max_len]}..." : val.inspect
                  else val.inspect
                  end
            str[0..max_len]
          end

          def render(frame, tui, area)
            lines = state_lines
            visible = lines[@scroll, area.height - 2] || []

            frame.render_widget(
              tui.paragraph(
                text: visible.join("\n"),
                block: tui.block(
                  title: "State Inspector (#{lines.size} vars)",
                  borders: [:all],
                  border_style: tui.style(fg: :yellow)
                )
              ),
              area
            )
          end
        end

        # Usage:
        @inspector = StateInspector.new(self)

        # Toggle with F12 or similar:
        if @show_inspector
          # Overlay on right side
          inspector_area = tui.rect(
            x: frame.area.width - 40,
            y: 0,
            width: 40,
            height: frame.area.height
          )
          @inspector.render(frame, tui, inspector_area)
        end
      RUBY
    },
    "event_logger" => {
      desc: "Log all events for debugging",
      code: <<~'RUBY'
        class EventLogger
          MAX_EVENTS = 100

          def initialize
            @events = []
          end

          def log(event)
            @events << { time: Time.now, event: event }
            @events.shift if @events.size > MAX_EVENTS
          end

          def recent(n = 10)
            @events.last(n)
          end

          def render(frame, tui, area)
            lines = recent(area.height - 2).map do |entry|
              time = entry[:time].strftime("%H:%M:%S")
              evt = entry[:event]
              case evt
              in { type: :key, code: code }
                "[#{time}] KEY: #{code}"
              in { type: :mouse, kind: kind, x: x, y: y }
                "[#{time}] MOUSE: #{kind} at (#{x},#{y})"
              in { type: :resize, width: w, height: h }
                "[#{time}] RESIZE: #{w}x#{h}"
              in { type: type }
                "[#{time}] #{type.upcase}"
              else
                "[#{time}] #{evt.inspect}"
              end
            end

            frame.render_widget(
              tui.paragraph(
                text: lines.join("\n"),
                block: tui.block(title: "Events", borders: [:all])
              ),
              area
            )
          end
        end

        # Usage:
        @event_log = EventLogger.new

        # In event loop:
        event = tui.poll_event
        @event_log.log(event) if @debug_mode
      RUBY
    },
    "full" => {
      desc: "Complete debug setup with all helpers",
      code: <<~'RUBY'
        # Complete debug setup for RatatuiRuby apps
        # Add to your app with: require_relative "debug_helpers"

        module DebugHelpers
          LOG_FILE = File.join(Dir.tmpdir, "tui_debug.log")

          # File logging
          def debug_log(msg, level: :info)
            return unless @debug_mode
            timestamp = Time.now.strftime("%H:%M:%S.%L")
            File.open(LOG_FILE, "a") { |f| f.puts "[#{timestamp}] [#{level}] #{msg}" }
          end

          # FPS tracking
          def init_fps_counter
            @fps_frames = []
            @fps_last_time = Time.now
          end

          def tick_fps
            now = Time.now
            @fps_frames << (now - @fps_last_time)
            @fps_frames.shift if @fps_frames.size > 60
            @fps_last_time = now
          end

          def current_fps
            return 0 if @fps_frames.empty?
            (1.0 / (@fps_frames.sum / @fps_frames.size)).round(1)
          end

          # Event logging
          def init_event_log
            @event_log = []
          end

          def log_event(event)
            return unless @debug_mode
            @event_log << { time: Time.now, event: event }
            @event_log.shift if @event_log.size > 50
          end

          # Render debug overlay
          def render_debug_overlay(frame, tui)
            return unless @debug_mode

            lines = [
              "FPS: #{current_fps}",
              "Events: #{@event_log&.size || 0}",
              "Vars: #{instance_variables.size}",
              ""
            ]

            # Recent events
            @event_log&.last(5)&.each do |e|
              lines << "  #{e[:event][:type]}"
            end

            w = 30
            h = lines.size + 2
            area = tui.rect(x: frame.area.width - w, y: 0, width: w, height: h)

            frame.render_widget(RatatuiRuby::Widgets::Clear.new, area)
            frame.render_widget(
              tui.paragraph(
                text: lines.join("\n"),
                block: tui.block(title: "[DEBUG]", borders: [:all], border_style: tui.style(fg: :yellow))
              ),
              area
            )
          end
        end

        # Usage in your app:
        #
        # class MyApp
        #   include DebugHelpers
        #
        #   def initialize
        #     @debug_mode = ENV["DEBUG"] == "1"
        #     init_fps_counter if @debug_mode
        #     init_event_log if @debug_mode
        #   end
        #
        #   def run
        #     RatatuiRuby.run do |tui|
        #       loop do
        #         tick_fps if @debug_mode
        #         tui.draw do |frame|
        #           render(frame, tui)
        #           render_debug_overlay(frame, tui)
        #         end
        #         event = tui.poll_event
        #         log_event(event)
        #         # ...
        #       end
        #     end
        #   end
        # end
        #
        # Run with: DEBUG=1 ruby my_app.rb
        # Tail log: tail -f /tmp/tui_debug.log
      RUBY
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
    puts template[:code]
  end
end

RatatuiDebug.run
