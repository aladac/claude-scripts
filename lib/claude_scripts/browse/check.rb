# frozen_string_literal: true

module ClaudeScripts
  module Browse
    class Check < Command
      PLUGIN = "browse"
      MARKETPLACE = "saiden"

      def run
        title "Browse Plugin Status"

        check_installed
        check_mcp
        check_processes
      end

      private

      def check_installed
        puts
        info "Installed Plugin"

        json = "#{Dir.home}/.claude/plugins/installed_plugins.json"
        return err("No plugin registry") unless File.exist?(json)

        data = read_json(json)
        plugin = data&.dig("plugins", "#{PLUGIN}@#{MARKETPLACE}", 0)

        if plugin
          ok "#{PLUGIN}@#{MARKETPLACE}"
          muted "  Version: #{plugin['version']}"
          muted "  Commit: #{plugin['gitCommitSha']&.[](0, 7)}"
          muted "  Scope: #{plugin['scope']}"
        else
          err "Not installed"
        end
      end

      def check_mcp
        puts
        info "MCP Configuration"

        cache = "#{Dir.home}/.claude/plugins/cache/#{MARKETPLACE}/#{PLUGIN}"
        return muted("No cache found") unless Dir.exist?(cache)

        version_dir = Dir.glob("#{cache}/*").find { |f| File.directory?(f) }
        return unless version_dir

        mcp = "#{version_dir}/.claude-plugin/.mcp.json"
        return unless File.exist?(mcp)

        data = read_json(mcp)
        servers = data&.dig("mcpServers")&.keys || []
        ok "Servers: #{servers.join(', ')}"
      end

      def check_processes
        puts
        info "Running Processes"

        procs = `pgrep -fl "browse-mcp|browse.*mcp" 2>/dev/null`.strip
        if procs.empty?
          muted "No browse MCP processes"
        else
          procs.each_line do |line|
            pid, cmd = line.strip.split(" ", 2)
            ok "PID #{pid}: #{cmd[0, 50]}"
          end
        end
      end
    end
  end
end
