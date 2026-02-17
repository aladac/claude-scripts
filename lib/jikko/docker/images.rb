# frozen_string_literal: true

module Jikko
  module Docker
    class Images < Command
      def run
        sh "docker images"
      end
    end
  end
end
