# frozen_string_literal: true

module Jikko
  module CF
    class PagesList < Command
      def run
        `wrangler pages project list 2>&1`.lines.drop(3).each { |l| puts l }
      end
    end
  end
end
