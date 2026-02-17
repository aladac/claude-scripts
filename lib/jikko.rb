# frozen_string_literal: true

require "cli/ui"
require_relative "jikko/version"
require_relative "jikko/command"
require_relative "jikko/router"

module Jikko
  CLI::UI.enable_color = true
  CLI::UI::StdoutRouter.enable

  class << self
    def run(args = ARGV)
      Router.call(args)
    end
  end
end
