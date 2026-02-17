# frozen_string_literal: true

module Jikko
  module Git
    class Log < Command
      def run
        sh "git log --oneline -20"
      end
    end
  end
end
