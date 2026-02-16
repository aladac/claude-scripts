# frozen_string_literal: true

require "json"
require "fileutils"

module ClaudeScripts
  class Command
    attr_reader :args

    def initialize(args = [])
      @args = args
    end

    def self.call(args = [])
      new(args).run
    end

    def run
      raise NotImplementedError
    end

    protected

    # ── Paths ──────────────────────────────────────────────────────────

    def claude_dir     = File.expand_path("~/.claude")
    def settings_path  = File.join(claude_dir, "settings.json")
    def home(path)     = path.sub(Dir.home, "~")

    # ── Output ─────────────────────────────────────────────────────────

    def puts(msg = "") = CLI::UI.puts(msg)
    def fmt(msg)       = CLI::UI.fmt(msg)

    def ok(msg)    = puts "{{v}} {{green:#{msg}}}"
    def warn(msg)  = puts "{{x}} {{yellow:#{msg}}}"
    def err(msg)   = puts "{{x}} {{red:#{msg}}}"
    def info(msg)  = puts "{{cyan:#{msg}}}"
    def muted(msg) = $stdout.puts "\e[90m#{msg}\e[0m"

    def title(msg)
      puts
      puts "{{bold:#{msg}}}"
      puts "{{cyan:─" * msg.length + "}}"
    end

    # ── Frames ─────────────────────────────────────────────────────────

    def frame(title, color: :cyan, &block)
      CLI::UI::Frame.open(title, color: color, &block)
    end

    # ── Spinners ───────────────────────────────────────────────────────

    def spin(title, &block)
      CLI::UI::Spinner.spin(title, &block)
    end

    def spin_group
      CLI::UI::SpinGroup.new.tap do |group|
        yield group
        group.wait
      end
    end

    # ── Tables ─────────────────────────────────────────────────────────

    def table(headers, rows)
      return if rows.empty?

      widths = headers.each_with_index.map do |h, i|
        [h.to_s.length, rows.map { |r| r[i].to_s.length }.max || 0].max
      end

      header_row = headers.each_with_index.map { |h, i| "\e[1;36m#{h.to_s.ljust(widths[i])}\e[0m" }.join(" │ ")
      separator = widths.map { |w| "─" * w }.join("─┼─")

      $stdout.puts " #{header_row} "
      $stdout.puts "─#{separator}─"
      rows.each do |row|
        line = row.each_with_index.map { |c, i| c.to_s.ljust(widths[i]) }.join(" │ ")
        $stdout.puts " #{line} "
      end
    end

    # ── Prompts ────────────────────────────────────────────────────────

    def ask(question, default: nil)
      CLI::UI.ask(question, default: default)
    end

    def confirm?(question)
      CLI::UI.confirm(question)
    end

    def select(question, options)
      CLI::UI.ask(question, options: options)
    end

    # ── JSON ───────────────────────────────────────────────────────────

    def read_json(path)
      return nil unless File.exist?(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      nil
    end

    def write_json(path, data)
      File.write(path, JSON.pretty_generate(data) + "\n")
    end

    # ── Shell ──────────────────────────────────────────────────────────

    def sh(cmd, capture: false)
      capture ? `#{cmd}` : system(cmd)
    end

    def sh!(cmd)
      result = `#{cmd} 2>&1`
      [$?.success?, result]
    end
  end
end
