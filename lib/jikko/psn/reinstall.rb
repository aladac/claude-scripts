# frozen_string_literal: true

module Jikko
  module PSN
    class Reinstall < Command
      DIR = File.expand_path("~/Projects/psn")

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

          spin("Installing") { sh "pip install -e . --break-system-packages", capture: true }
        end
        ok "PSN reinstalled"
      end
    end
  end
end
