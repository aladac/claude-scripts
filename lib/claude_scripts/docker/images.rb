# frozen_string_literal: true

module ClaudeScripts
  module Docker
    class Images < Command
      def run
        sh "docker images"
      end
    end
  end
end
