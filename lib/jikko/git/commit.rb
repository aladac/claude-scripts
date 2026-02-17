# frozen_string_literal: true

module Jikko
  module Git
    class Commit < Command
      def run
        spin("Staging files") { sh "git add -A" }

        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        count = `git diff --cached --numstat`.lines.size

        spin("Committing") do
          sh "git commit -m '[Update] #{timestamp}, #{count} files'"
        end

        ok "Committed #{count} files"
      end
    end
  end
end
