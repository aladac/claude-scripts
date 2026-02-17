# frozen_string_literal: true

module Jikko
  module Router
    COMMANDS_PATH = File.expand_path(".", __dir__)

    class << self
      def call(args)
        if args.empty? || args.first == "help"
          show_help
          return
        end

        if args.first == "version" || args.first == "-v"
          puts "jikko #{VERSION}"
          return
        end

        command_path, command_args = parse_args(args)
        command_class = resolve(command_path)

        if command_class
          command_class.call(command_args)
        else
          CLI::UI.puts "{{red:Unknown command: #{command_path.join(' ')}}}"
          CLI::UI.puts "Run {{bold:jikko help}} for available commands"
          exit 1
        end
      end

      private

      def parse_args(args)
        # Find the longest command path that resolves to a valid command
        # e.g., ["commands", "add", "test", "foo"] -> [["commands", "add"], ["test", "foo"]]
        remaining = args.dup
        path = []

        # Try progressively longer paths until we can't find a matching file
        while remaining.any? && !remaining.first.start_with?("-")
          candidate = path + [remaining.first]
          file_path = File.join(COMMANDS_PATH, *candidate) + ".rb"

          if File.exist?(file_path)
            path << remaining.shift
          elsif File.directory?(File.join(COMMANDS_PATH, *candidate))
            # It's a directory, keep going
            path << remaining.shift
          else
            # No file and not a directory, stop here
            break
          end
        end

        [path, remaining]
      end

      def resolve(path)
        return nil if path.empty?

        # Try to load and find the command class
        # git status -> jikko/git/status.rb -> Jikko::Git::Status
        file_path = File.join(COMMANDS_PATH, *path) + ".rb"

        if File.exist?(file_path)
          require file_path
          class_name = path.map { |p| camelize(p) }.join("::")
          const_get("Jikko::#{class_name}")
        else
          nil
        end
      rescue NameError
        nil
      end

      ACRONYMS = %w[ai sd api ui cf cl ps psn].freeze

      def camelize(str)
        return str.upcase if ACRONYMS.include?(str.downcase)

        str.split(/[_-]/).map(&:capitalize).join
      end

      def show_help
        CLI::UI.puts "{{bold:jikko}} v#{VERSION}"
        CLI::UI.puts ""
        CLI::UI.puts "{{cyan:Usage:}} jikko <command> [args]"
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
