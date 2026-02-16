# frozen_string_literal: true

module ClaudeScripts
  module Git
    class Branches < Command
      def run
        output = `git for-each-ref --sort=-committerdate refs/heads/ \
          --format="%(refname:short)\t%(objectname:short)\t%(contents:subject)\t%(authorname)\t%(committerdate:relative)" \
          | head -20`

        rows = output.each_line.map { |l| l.strip.split("\t") }

        if rows.empty?
          muted "No branches found"
        else
          table(%w[Branch Hash Message Author Age], rows)
        end
      end
    end
  end
end
