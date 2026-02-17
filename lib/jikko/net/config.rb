# frozen_string_literal: true

module Jikko
  module Net
    class Config < Command
      def run
        title "Network Interfaces"
        sh "networksetup -listallhardwareports"
      end
    end
  end
end
