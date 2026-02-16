# frozen_string_literal: true

module ClaudeScripts
  module CF
    class InitPages < Command
      def run
        project = args.first || return err("Usage: cf init_pages <project>")
        sh "wrangler pages project create #{project}"
      end
    end
  end
end
