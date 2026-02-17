# frozen_string_literal: true

module Jikko
  class Install < Command
    REPO_DIR = File.expand_path("~/Projects/claude-scripts")
    COMMANDS_SRC = File.join(REPO_DIR, "commands")
    COMMANDS_DST = File.expand_path("~/.claude/commands")

    def run
      force = args.include?("--force") || args.include?("-f")
      copy = args.include?("--copy") || args.include?("-c")

      title "Install jikko commands"

      unless Dir.exist?(COMMANDS_SRC)
        err "Source not found: #{home(COMMANDS_SRC)}"
        return
      end

      if File.exist?(COMMANDS_DST) || File.symlink?(COMMANDS_DST)
        if force
          FileUtils.rm_rf(COMMANDS_DST)
          ok "Removed existing: #{home(COMMANDS_DST)}"
        else
          existing = File.symlink?(COMMANDS_DST) ? "symlink" : "directory"
          err "Already exists (#{existing}): #{home(COMMANDS_DST)}"
          info "Use --force to overwrite"
          return
        end
      end

      if copy
        FileUtils.cp_r(COMMANDS_SRC, COMMANDS_DST)
        ok "Copied to: #{home(COMMANDS_DST)}"
      else
        FileUtils.ln_s(COMMANDS_SRC, COMMANDS_DST)
        ok "Symlinked: #{home(COMMANDS_DST)} -> #{home(COMMANDS_SRC)}"
      end

      count = Dir.glob(File.join(COMMANDS_DST, "**", "*.md")).size
      info "#{count} commands installed"
    end
  end
end
