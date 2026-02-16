# frozen_string_literal: true

module ClaudeScripts
  module CF
    class PagesList < Command
      def run
        `wrangler pages project list 2>&1`.lines.drop(3).each { |l| puts l }
      end
    end
  end
end
