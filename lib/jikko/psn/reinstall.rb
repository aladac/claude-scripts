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
          unless `git status --porcelain`.strip.empty?
            spin("Committing") do
              sh "git add -A && git commit -m 'Update #{Time.now.strftime("%Y-%m-%d %H:%M")}' && git push", capture: true
            end
          end

          # Update __init__.py with version
          spin("Versioning") do
            content = File.read(INIT_FILE)
            updated = content.gsub(/__version__ = "[^"]+"/, "__version__ = \"#{full_version}\"")
            File.write(INIT_FILE, updated)
          end

          spin("Installing") { sh "pip3 install -e . --break-system-packages", capture: true }
        end
        ok "PSN reinstalled [#{full_version}]"
      end

      private

      def full_version
        @full_version ||= begin
          commit_hash = `git -C #{DIR} rev-parse --short HEAD`.strip
          "#{BASE_VERSION}+#{commit_hash}"
        end
      end
    end
  end
end
