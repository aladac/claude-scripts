# frozen_string_literal: true

module ClaudeScripts
  module Git
    class ForcePush < Command
      def run
        Empty.call
        branch = `git branch --show-current`.strip
        puts
        warn "Force pushing #{branch}..."
        sh "git push --force origin #{branch}"
      end
    end
  end
end
