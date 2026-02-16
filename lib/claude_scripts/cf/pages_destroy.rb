# frozen_string_literal: true

module ClaudeScripts
  module CF
    class PagesDestroy < Command
      def run
        project = args.first || return err("Usage: cf pages_destroy <project>")
        sh "wrangler pages project delete #{project}"
      end
    end
  end
end
