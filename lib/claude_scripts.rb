# frozen_string_literal: true

require "cli/ui"
require_relative "claude_scripts/version"
require_relative "claude_scripts/command"
require_relative "claude_scripts/router"

module ClaudeScripts
  CLI::UI.enable_color = true
  CLI::UI::StdoutRouter.enable

  class << self
    def run(args = ARGV)
      Router.call(args)
    end
  end
end
