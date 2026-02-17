#!/usr/bin/env ruby
# frozen_string_literal: true

require "cli/ui"
require "tty-table"
require "json"
require "optparse"
require "fileutils"

CLI::UI.enable_color = true
CLI::UI::StdoutRouter.enable

module Claude
  # Base class for Claude Code CLI scripts
  # Uses CLI::UI for terminal output
  #
  # Subclasses should define METADATA:
  #   METADATA = { name: "docker:ps", desc: "List running containers" }
  #
  class Generator
    METADATA = { name: "command", desc: "No description" }.freeze

    attr_reader :args, :options

    def initialize(args = ARGV)
      @args = args.dup
      @options = {}
      parse_options!
    end

    def self.run(args = ARGV)
      new(args).execute
    end

    # Override in subclasses
    def execute
      raise NotImplementedError, "Subclasses must implement #execute"
    end

    # Override to define CLI options
    def define_options(parser)
      # Subclasses add options here
    end

    protected

    # ─────────────────────────────────────────────────────────────────
    # Common paths
    # ─────────────────────────────────────────────────────────────────

    def claude_dir     = File.expand_path("~/.claude")
    def settings_path  = File.join(claude_dir, "settings.json")
    def commands_dir   = File.join(claude_dir, "commands")
    def scripts_dir    = File.join(claude_dir, "scripts/commands")
    def plugins_dir    = File.join(claude_dir, "plugins")
    def projects_dir   = File.expand_path("~/Projects")
    def home_path(path) = path.sub(Dir.home, "~")

    # ─────────────────────────────────────────────────────────────────
    # Output helpers (CLI::UI)
    # ─────────────────────────────────────────────────────────────────

    def puts(msg = "")
      CLI::UI.puts(msg)
    end

    def fmt(msg)
      CLI::UI.fmt(msg)
    end

    def ok(msg)
      puts "{{v}} {{green:#{msg}}}"
    end

    def warn(msg)
      puts "{{x}} {{yellow:#{msg}}}"
    end

    def err(msg)
      puts "{{x}} {{red:#{msg}}}"
    end

    def info(msg)
      puts "  {{cyan:#{msg}}}"
    end

    def bold(msg)
      puts "{{bold:#{msg}}}"
    end

    def muted(msg)
      # CLI::UI doesn't support faint, use ANSI directly
      STDOUT.puts "\e[90m#{msg}\e[0m"
    end

    def hr(width = 40)
      puts "─" * width
    end

    # ─────────────────────────────────────────────────────────────────
    # Frames and sections
    # ─────────────────────────────────────────────────────────────────

    def frame(title, color: :cyan, &block)
      CLI::UI::Frame.open(title, color: color, &block)
    end

    def section(title)
      puts
      puts "{{bold:{{cyan:#{title}}}}}"
      hr(title.length + 5)
    end

    # ─────────────────────────────────────────────────────────────────
    # Spinners and progress
    # ─────────────────────────────────────────────────────────────────

    def spin(title, &block)
      CLI::UI::Spinner.spin(title, &block)
    end

    def spin_group(&block)
      CLI::UI::SpinGroup.new(&block)
    end

    # ─────────────────────────────────────────────────────────────────
    # Prompts
    # ─────────────────────────────────────────────────────────────────

    def ask(question, default: nil)
      CLI::UI.ask(question, default: default)
    end

    def confirm?(question)
      CLI::UI.confirm(question)
    end

    def select(question, choices)
      CLI::UI.ask(question, options: choices)
    end

    # ─────────────────────────────────────────────────────────────────
    # Tables (TTY::Table)
    # ─────────────────────────────────────────────────────────────────

    def table(headers, rows, **opts)
      colored_headers = headers.map { |h| "\e[1;36m#{h}\e[0m" }
      t = TTY::Table.new(colored_headers, rows)
      STDOUT.puts t.render(:unicode, padding: [0, 1], **opts)
    end

    # ─────────────────────────────────────────────────────────────────
    # JSON helpers
    # ─────────────────────────────────────────────────────────────────

    def read_json(path)
      return nil unless File.exist?(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      err "Failed to parse #{path}"
      nil
    end

    def write_json(path, data)
      File.write(path, JSON.pretty_generate(data) + "\n")
    end

    def update_json(path, &block)
      data = read_json(path) || {}
      yield(data)
      write_json(path, data)
    end

    # ─────────────────────────────────────────────────────────────────
    # File operations
    # ─────────────────────────────────────────────────────────────────

    def create_file(path, content, force: false)
      if File.exist?(path) && !force
        warn "File exists: #{home_path(path)}"
        return false
      end
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      ok "Created #{home_path(path)}"
      true
    end

    def append_to_file(path, content)
      File.open(path, "a") { |f| f.puts(content) }
      ok "Updated #{home_path(path)}"
    end

    def file_exists?(path)
      File.exist?(path)
    end

    # ─────────────────────────────────────────────────────────────────
    # Shell helpers
    # ─────────────────────────────────────────────────────────────────

    def run(cmd, capture: false, silent: false)
      if capture
        `#{cmd}`
      elsif silent
        system(cmd, out: File::NULL, err: File::NULL)
      else
        system(cmd)
      end
    end

    def run_with_spinner(title, cmd)
      result = nil
      spin(title) do
        result = `#{cmd} 2>&1`
        $?.success? ? :success : :failure
      end
      result
    end

    # ─────────────────────────────────────────────────────────────────
    # Git helpers
    # ─────────────────────────────────────────────────────────────────

    def git_clean?(dir = Dir.pwd)
      Dir.chdir(dir) { `git status --porcelain 2>/dev/null`.strip.empty? }
    end

    def git_commit_short(dir = Dir.pwd)
      Dir.chdir(dir) { `git rev-parse --short HEAD 2>/dev/null`.strip }
    end

    def git_branch(dir = Dir.pwd)
      Dir.chdir(dir) { `git branch --show-current 2>/dev/null`.strip }
    end

    def git_unpushed_count(dir = Dir.pwd)
      Dir.chdir(dir) { `git log @{u}..HEAD --oneline 2>/dev/null`.lines.size }
    end

    # ─────────────────────────────────────────────────────────────────
    # MCP helpers
    # ─────────────────────────────────────────────────────────────────

    def mcp_servers(path)
      data = read_json(path)
      servers = data&.dig("mcpServers")&.keys || []
      servers.empty? ? "(none)" : servers.join(", ")
    end

    def check_file(path, label, show_lines: false)
      return false unless File.exist?(path)
      extra = show_lines ? " (#{File.readlines(path).size} lines)" : ""
      ok "#{label}#{extra}"
      info home_path(path)
      true
    end

    private

    def parse_options!
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
        define_options(opts)
        opts.on("-h", "--help", "Show this help") do
          STDOUT.puts opts
          exit
        end
      end
      parser.parse!(@args)
    rescue OptionParser::InvalidOption => e
      err e.message
      exit 1
    end
  end
end
