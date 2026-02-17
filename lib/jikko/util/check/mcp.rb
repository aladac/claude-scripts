# frozen_string_literal: true

module Jikko
  module Util
    module Check
      class Mcp < Command
        def run
          title "MCP Configuration"
          muted "pwd: #{Dir.pwd}"

          check_current
          check_parents
          check_global
        end

        private

        def check_current
          puts
          info "Current Directory"

          found = Dir.glob("./**/{.mcp.json,mcp.json}")
                     .reject { |f| f.include?("node_modules") }

          if found.empty?
            muted "(none)"
          else
            found.each do |f|
              ok "#{f}: #{servers(f)}"
            end
          end
        end

        def check_parents
          puts
          info "Parent Directories"

          dir = File.dirname(Dir.pwd)
          found = 0

          while dir != "/"
            %w[.mcp.json mcp.json].each do |name|
              path = File.join(dir, name)
              next unless File.exist?(path)
              found += 1
              warn "#{home(path)}: #{servers(path)}"
            end
            dir = File.dirname(dir)
          end

          muted "(none)" if found == 0
        end

        def check_global
          puts
          info "Global Configs"

          settings = "#{Dir.home}/.claude/settings.json"
          if File.exist?(settings)
            data = read_json(settings)
            s = data&.dig("mcpServers")&.keys || []
            ok "settings.json: #{s.join(', ')}" if s.any?
          end

          # Plugins
          cache = "#{Dir.home}/.claude/plugins/cache"
          return unless Dir.exist?(cache)

          Dir.glob("#{cache}/**/.claude-plugin/{.mcp.json,mcp.json}").each do |f|
            ok "Plugin: #{servers(f)}"
          end
        end

        def servers(path)
          data = read_json(path)
          s = data&.dig("mcpServers")&.keys || []
          s.empty? ? "(none)" : s.join(", ")
        end
      end
    end
  end
end
