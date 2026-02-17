# frozen_string_literal: true

module Jikko
  module PSN
    class Reinstall < Command
      DIR = File.expand_path("~/Projects/psn")
      INIT_FILE = File.join(DIR, "src/personality/__init__.py")
      BASE_VERSION = "0.1.0"

      def run
        unless Dir.exist?(DIR)
          err "Not found: #{DIR}"
          return
        end

        Dir.chdir(DIR) do
          # Exclude __init__.py (version file) from dirty check
          dirty = `git status --porcelain`.strip.lines.reject { |l| l.include?("__init__.py") }.any?
          commit = `git rev-parse --short HEAD`.strip
          installed = `psn --version 2>/dev/null`.strip.sub("psn version ", "")
          target = "#{BASE_VERSION}+#{commit}"

          # Up to date: repo clean and version matches
          if !dirty && installed == target
            ok "PSN up to date [#{installed}]"
            return
          end

          if dirty
            spin("Committing") do
              sh "git add -A && git commit -m 'Update #{Time.now.strftime("%Y-%m-%d %H:%M")}' && git push", capture: true
            end
            commit = `git rev-parse --short HEAD`.strip
            target = "#{BASE_VERSION}+#{commit}"
          end

          spin("Versioning") do
            content = File.read(INIT_FILE)
            updated = content.gsub(/__version__ = "[^"]+"/, "__version__ = \"#{target}\"")
            File.write(INIT_FILE, updated)
          end

          spin("Installing") { sh "pip3 install -e . --break-system-packages", capture: true }

          ok "PSN reinstalled [#{target}]"
        end
      end
    end
  end
end
