# frozen_string_literal: true

module ClaudeScripts
  module Router
    COMMANDS_PATH = File.expand_path(".", __dir__)

    class << self
      def call(args)
        if args.empty? || args.first == "help"
          show_help
          return
        end

        if args.first == "version" || args.first == "-v"
          puts "claude-scripts #{VERSION}"
          return
        end

        command_path, command_args = parse_args(args)
        command_class = resolve(command_path)

        if command_class
          command_class.call(command_args)
        else
          CLI::UI.puts "{{red:Unknown command: #{command_path.join(' ')}}}"
          CLI::UI.puts "Run {{bold:claude-scripts help}} for available commands"
          exit 1
        end
      end

      private

      def parse_args(args)
        # Find where command path ends and args begin
        # e.g., ["git", "status", "--verbose"] -> [["git", "status"], ["--verbose"]]
        path = []
        remaining = args.dup

        while remaining.any? && !remaining.first.start_with?("-")
          path << remaining.shift
        end

        [path, remaining]
      end

      def resolve(path)
        return nil if path.empty?

        # Try to load and find the command class
        # git status -> claude_scripts/git/status.rb -> ClaudeScripts::Git::Status
        file_path = File.join(COMMANDS_PATH, *path) + ".rb"

        if File.exist?(file_path)
          require file_path
          class_name = path.map { |p| camelize(p) }.join("::")
          const_get("ClaudeScripts::#{class_name}")
        else
          nil
        end
      rescue NameError
        nil
      end

      def camelize(str)
        str.split(/[_-]/).map(&:capitalize).join
      end

      def show_help
        CLI::UI.puts "{{bold:claude-scripts}} v#{VERSION}"
        CLI::UI.puts ""
        CLI::UI.puts "{{cyan:Usage:}} claude-scripts <command> [args]"
        CLI::UI.puts ""
        CLI::UI.puts "{{cyan:Commands:}}"

        # Scan for available commands
        commands = Dir.glob(File.join(COMMANDS_PATH, "**", "*.rb"))
                      .reject { |f| %w[command router version].include?(File.basename(f, ".rb")) }
                      .map { |f| f.sub("#{COMMANDS_PATH}/", "").sub(".rb", "").gsub("/", " ") }
                      .sort

        commands.each do |cmd|
          CLI::UI.puts "  #{cmd}"
        end
      end
    end
  end
end
