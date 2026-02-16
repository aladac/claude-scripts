# frozen_string_literal: true

module ClaudeScripts
  module Git
    class Diff < Command
      def run
        sh "git diff"
      end
    end
  end
end
