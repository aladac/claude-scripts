# frozen_string_literal: true

module Jikko
  module Git
    class Push < Command
      def run
        Commit.call(args)
        puts
        info "Pushing..."
        sh "git push"
      end
    end
  end
end
