# frozen_string_literal: true

module ClaudeScripts
  module CF
    class Wrangler < Command
      def run
        title "Workers"
        sh "wrangler deployments list 2>/dev/null || echo '(none)'"
        puts
        title "Pages"
        `wrangler pages project list 2>&1`.lines.drop(3).each { |l| puts l }
      end
    end
  end
end
