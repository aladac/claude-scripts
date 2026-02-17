# frozen_string_literal: true

module Jikko
  module SD
    class UpdateTensors < Command
      DIR = File.expand_path("~/Projects/tensors")

      def run
        Dir.chdir(DIR) do
          return ok("Already clean") if `git status --porcelain`.strip.empty?
          spin("Committing") do
            sh "git add -A && git commit -m 'Update #{Time.now.strftime("%Y-%m-%d %H:%M")}' && git push", capture: true
          end
        end
        ok "tensors updated"
      end
    end
  end
end
