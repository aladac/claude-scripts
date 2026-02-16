# frozen_string_literal: true

module ClaudeScripts
  module Git
    class Empty < Command
      def run
        timestamp = Time.now.strftime("%Y-%m-%d_%H:%M:%S")
        sh "git commit --allow-empty -m '#{timestamp} Update'"
        ok "Empty commit created"
      end
    end
  end
end
