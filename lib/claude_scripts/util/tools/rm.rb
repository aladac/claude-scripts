# frozen_string_literal: true

module ClaudeScripts
  module Util
    module Tools
      class Rm < Command
        def run
          permission = args.first
          unless permission
            err "Usage: claude-scripts util tools rm <permission>"
            return
          end

          data = read_json(settings_path)
          unless data
            err "No settings.json found"
            return
          end

          permissions = data.dig("permissions", "allow") || []
          unless permissions.include?(permission)
            warn "Not in whitelist: #{permission}"
            return
          end

          data["permissions"]["allow"].delete(permission)
          write_json(settings_path, data)
          ok "Removed: #{permission}"
        end
      end
    end
  end
end
