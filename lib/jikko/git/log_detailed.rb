# frozen_string_literal: true

module Jikko
  module Git
    class LogDetailed < Command
      def run
        output = `git log --pretty=format:"%ad\t%h\t%s\t%an" --date=short -20`

        rows = output.each_line.map { |l| l.strip.split("\t") }

        if rows.empty?
          muted "No commits found"
        else
          table(%w[Date Hash Message Author], rows)
        end
      end
    end
  end
end
