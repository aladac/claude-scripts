# frozen_string_literal: true

module ClaudeScripts
  module CL
    class Scripts < Command
      SCRIPTS_DIR = File.expand_path("~/Projects/claude-scripts")

      def run
        frame("claude-scripts", color: :cyan) do
          info "Version: #{VERSION}"
          info "Path: #{home(SCRIPTS_DIR)}"
          puts

          show_status
          puts

          show_commands
        end
      end

      private

      def show_status
        title "Git Status"
        Dir.chdir(SCRIPTS_DIR) do
          branch = `git branch --show-current`.strip
          status = `git status --porcelain`.strip
          last_commit = `git log -1 --format='%h %s'`.strip

          info "Branch: #{branch}"
          info "Last: #{last_commit}"

          if status.empty?
            ok "Working tree clean"
          else
            warn "Uncommitted changes:"
            status.lines.each { |l| muted "  #{l.strip}" }
          end
        end
      end

      def show_commands
        title "Available Commands"
        commands_dir = File.join(SCRIPTS_DIR, "lib/claude_scripts")

        commands = Dir.glob(File.join(commands_dir, "**", "*.rb"))
                      .reject { |f| %w[command router version].include?(File.basename(f, ".rb")) }
                      .map { |f| f.sub("#{commands_dir}/", "").sub(".rb", "").tr("/", " ") }
                      .sort

        commands.each_slice(3).each do |row|
          muted row.map { |c| c.ljust(24) }.join
        end
      end
    end
  end
end
