# frozen_string_literal: true

module Jikko
  module CF
    class PagesDestroy < Command
      def run
        project = args.first || return err("Usage: cf pages_destroy <project>")
        sh "wrangler pages project delete #{project}"
      end
    end
  end
end
