# frozen_string_literal: true

module ClaudeScripts
  module Util
    module Tools
      class Ls < Command
        def run
          data = read_json(settings_path)
          permissions = data&.dig("permissions", "allow") || []

          if permissions.empty?
            muted "No tool permissions whitelisted"
            return
          end

          title "Whitelisted Permissions"
          permissions.each { |p| puts "  #{p}" }
        end
      end
    end
  end
end
