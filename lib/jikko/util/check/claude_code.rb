# frozen_string_literal: true

module Jikko
  module Util
    module Check
      class ClaudeCode < Command
        def run
          title "Claude Code Configuration"
          muted "pwd: #{Dir.pwd}"

          check_settings
          check_memory
          check_mcp
        end

        private

        def check_settings
          puts
          info "Settings Files"

          [
            ["/Library/Application Support/ClaudeCode/managed-settings.json", "Managed"],
            [".claude/settings.local.json", "Local"],
            [".claude/settings.json", "Project"],
            ["#{Dir.home}/.claude/settings.json", "User"]
          ].each do |path, label|
            check_exists(path, label)
          end
        end

        def check_memory
          puts
          info "Memory Files (CLAUDE.md)"

          [
            ["CLAUDE.local.md", "Local"],
            ["CLAUDE.md", "Project"],
            [".claude/CLAUDE.md", "Project"],
            ["#{Dir.home}/.claude/CLAUDE.md", "User"]
          ].each do |path, label|
            next unless File.exist?(path)
            lines = File.readlines(path).size
            ok "#{label} (#{lines} lines)"
          end

          # Auto memory
          project_key = Dir.pwd.gsub("/", "-").sub(/^-/, "")
          auto_mem = "#{Dir.home}/.claude/projects/#{project_key}/memory/MEMORY.md"
          if File.exist?(auto_mem)
            lines = File.readlines(auto_mem).size
            ok "Auto memory (#{lines} lines)"
          end
        end

        def check_mcp
          puts
          info "MCP Configuration"

          [".mcp.json", "mcp.json"].each do |name|
            next unless File.exist?(name)
            servers = mcp_servers(name)
            ok "#{name}: #{servers}"
          end

          settings = "#{Dir.home}/.claude/settings.json"
          if File.exist?(settings)
            data = read_json(settings)
            servers = data&.dig("mcpServers")&.keys || []
            ok "settings.json: #{servers.join(', ')}" if servers.any?
          end
        end

        def check_exists(path, label)
          ok "#{label}: #{home(path)}" if File.exist?(path)
        end

        def mcp_servers(path)
          data = read_json(path)
          servers = data&.dig("mcpServers")&.keys || []
          servers.empty? ? "(none)" : servers.join(", ")
        end
      end
    end
  end
end
