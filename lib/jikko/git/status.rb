# frozen_string_literal: true

module Jikko
  module Git
    class Status < Command
      def run
        sh "git status"
      end
    end
  end
end
