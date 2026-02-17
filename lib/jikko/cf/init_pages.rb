# frozen_string_literal: true

module Jikko
  module CF
    class InitPages < Command
      def run
        project = args.first || return err("Usage: cf init_pages <project>")
        sh "wrangler pages project create #{project}"
      end
    end
  end
end
