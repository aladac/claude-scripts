# frozen_string_literal: true

module ClaudeScripts
  module Commands
    class Add < Command
      COMMANDS_DIR = File.expand_path("~/.claude/commands")

      def run
        category, name, desc = args[0], args[1], args[2] || "TODO"

        unless category && name
          err "Usage: claude-scripts commands add <category> <name> [description]"
          return
        end

        cmd_dir = File.join(COMMANDS_DIR, category)
        cmd_file = File.join(cmd_dir, "#{name}.md")

        if File.exist?(cmd_file)
          err "Already exists: #{cmd_file}"
          return
        end

        FileUtils.mkdir_p(cmd_dir)
        File.write(cmd_file, <<~MD)
          ---
          description: #{desc}
          ---
          ```bash
          claude-scripts #{category.tr('/', ' ')} #{name} $ARGUMENTS
          ```
        MD

        ok "Created: #{cmd_file}"
        info "Usage: /#{category.tr('/', ':')}:#{name}"
      end
    end
  end
end
