# frozen_string_literal: true

module Jikko
  module SD
    class UpdateTengu < Command
      DIR = File.expand_path("~/Projects/tengu")

      def run
        Dir.chdir(DIR) do
          commit_if_dirty
          spin("Building") { sh "bun run build", capture: true }
          spin("Deploying") { sh "wrangler pages deploy dist --project-name=tengu", capture: true }
        end
        ok "tengu.to updated"
      end

      private

      def commit_if_dirty
        return if `git status --porcelain`.strip.empty?
        spin("Committing") do
          sh "git add -A && git commit -m 'Update #{Time.now.strftime("%Y-%m-%d %H:%M")}' && git push", capture: true
        end
      end
    end
  end
end
