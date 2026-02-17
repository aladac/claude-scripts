# frozen_string_literal: true

module Jikko
  module SD
    class UpdateWebsites < Command
      def run
        title "Updating all websites"
        UpdateSaiden.call
        UpdateTengu.call
        UpdateTensors.call
        ok "All done"
      end
    end
  end
end
