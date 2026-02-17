# frozen_string_literal: true

module Jikko
  module Util
    module Tools
      class Add < Command
        def run
          permission = args.first
          unless permission
            err "Usage: jikko util tools add <permission>"
            return
          end

          data = read_json(settings_path) || {}
          data["permissions"] ||= {}
          data["permissions"]["allow"] ||= []

          if data["permissions"]["allow"].include?(permission)
            warn "Already whitelisted: #{permission}"
            return
          end

          data["permissions"]["allow"] << permission
          write_json(settings_path, data)
          ok "Added: #{permission}"
        end
      end
    end
  end
end
