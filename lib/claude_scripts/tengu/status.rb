# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module ClaudeScripts
  module Tengu
    class Status < Command
      # Host configurations - extensible for future hosts
      HOSTS = {
        "junkpile" => {
          ssh: "chi@junkpile",
          api: "http://junkpile:8080",
          description: "Local development server"
        }
        # Future: "tengu" => { ssh: "chi@ssh.tengu.to", api: "https://api.tengu.to", ... }
      }.freeze

      DEFAULT_HOST = "junkpile"

      def run
        parse_args
        @host = HOSTS[@host_key]

        unless @host
          err "Unknown host: #{@host_key}"
          err "Available hosts: #{HOSTS.keys.join(', ')}"
          return
        end

        @results = { host: @host_key, checks: {} }

        title "Tengu Status: #{@host_key}"
        info @host[:description]

        check_ssh_connectivity
        check_service_status
        check_api_health
        check_version
        check_system_resources
        list_apps unless @quick

        if @json_output
          $stdout.puts JSON.pretty_generate(@results)
        else
          show_summary
        end
      end

      private

      def parse_args
        @host_key = DEFAULT_HOST
        @json_output = false
        @quick = false

        args.each_with_index do |arg, i|
          case arg
          when "-H", "--host"
            @host_key = args[i + 1] if args[i + 1]
          when "-j", "--json"
            @json_output = true
          when "-q", "--quick"
            @quick = true
          end
        end
      end

      def check_ssh_connectivity
        frame("SSH Connectivity", color: :cyan) do
          result = spin("Testing SSH connection") do
            system("ssh -o ConnectTimeout=5 -o BatchMode=yes #{@host[:ssh]} 'echo ok' >/dev/null 2>&1")
          end

          @results[:checks][:ssh] = result
          result ? ok("Connected to #{@host[:ssh]}") : err("Cannot connect to #{@host[:ssh]}")
        end
      end

      def check_service_status
        return unless @results[:checks][:ssh]

        frame("Service Status", color: :cyan) do
          output = run_ssh("systemctl is-active tengu 2>/dev/null || echo 'unknown'")
          status = output.strip

          @results[:checks][:service] = status
          case status
          when "active"
            ok "tengu.service is running"
          when "inactive"
            warn "tengu.service is stopped"
          when "failed"
            err "tengu.service has failed"
          else
            warn "tengu.service status: #{status}"
          end

          # Get uptime if running
          if status == "active"
            uptime = run_ssh("systemctl show tengu --property=ActiveEnterTimestamp --value 2>/dev/null").strip
            unless uptime.empty?
              info "Running since: #{uptime}"
              @results[:checks][:uptime] = uptime
            end
          end
        end
      end

      def check_api_health
        return unless @results[:checks][:ssh]

        frame("API Health", color: :cyan) do
          output = run_ssh("curl -s --connect-timeout 5 http://localhost:8080/health 2>/dev/null")

          begin
            health = JSON.parse(output)
            @results[:checks][:api_health] = health
            if health["status"] == "ok"
              ok "API responding: #{health['status']}"
            else
              warn "API status: #{health['status']}"
            end
          rescue JSON::ParserError
            @results[:checks][:api_health] = nil
            err "API not responding or invalid response"
          end
        end
      end

      def check_version
        return unless @results[:checks][:api_health]

        frame("Version Info", color: :cyan) do
          output = run_ssh("curl -s --connect-timeout 5 http://localhost:8080/version 2>/dev/null")

          begin
            version = JSON.parse(output)
            @results[:checks][:version] = version

            info "Name:    #{version['name']}"
            info "Version: #{version['version']}"
            info "Commit:  #{version['commit']}"
          rescue JSON::ParserError
            warn "Could not fetch version info"
          end
        end
      end

      def check_system_resources
        return unless @results[:checks][:ssh]

        frame("System Resources", color: :cyan) do
          # Disk usage for /var/lib/tengu
          disk = run_ssh("df -h /var/lib/tengu 2>/dev/null | tail -1 | awk '{print $3\"/\"$2\" (\"$5\" used)\"}'").strip
          unless disk.empty? || disk.include?("No such")
            info "Tengu data: #{disk}"
            @results[:checks][:disk] = disk
          end

          # Memory
          mem = run_ssh("free -h | awk '/^Mem:/ {print $3\"/\"$2\" used\"}'").strip
          unless mem.empty?
            info "Memory:     #{mem}"
            @results[:checks][:memory] = mem
          end

          # Load average
          load_avg = run_ssh("cat /proc/loadavg | awk '{print $1\", \"$2\", \"$3}'").strip
          unless load_avg.empty?
            info "Load avg:   #{load_avg}"
            @results[:checks][:load] = load_avg
          end

          # Docker containers
          containers = run_ssh("docker ps -q 2>/dev/null | wc -l").strip.to_i
          info "Containers: #{containers} running"
          @results[:checks][:containers] = containers
        end
      end

      def list_apps
        return unless @results[:checks][:api_health]

        frame("Deployed Apps", color: :cyan) do
          # Need auth token for /api/apps - try to get it from config
          token_output = run_ssh("grep -Po '(?<=token = \")[^\"]+' /etc/tengu/config.toml 2>/dev/null || " \
                                 "cat /etc/tengu/env 2>/dev/null | grep TOKEN | cut -d= -f2").strip

          if token_output.empty?
            warn "Cannot fetch apps (no auth token found)"
            @results[:checks][:apps] = []
            return
          end

          output = run_ssh("curl -s --connect-timeout 5 -H 'Authorization: Bearer #{token_output}' " \
                          "http://localhost:8080/api/apps 2>/dev/null")

          begin
            apps = JSON.parse(output)
            @results[:checks][:apps] = apps

            if apps.empty?
              info "No apps deployed"
            else
              rows = apps.map do |app|
                status_color = app["status"] == "running" ? "\e[32m" : "\e[33m"
                [
                  app["name"],
                  "#{status_color}#{app['status']}\e[0m",
                  app["domain"] || "-",
                  app["created_at"]&.split("T")&.first || "-"
                ]
              end
              table(%w[Name Status Domain Created], rows)
            end
          rescue JSON::ParserError => e
            warn "Could not parse apps response: #{e.message}"
            @results[:checks][:apps] = []
          end
        end
      end

      def show_summary
        title "Summary"

        checks = @results[:checks]

        rows = [
          ["Host", @host_key],
          ["SSH", checks[:ssh] ? "OK" : "FAILED"],
          ["Service", checks[:service] || "N/A"],
          ["API", checks[:api_health] ? "OK" : "N/A"],
          ["Version", checks.dig(:version, "version") || "N/A"],
          ["Apps", checks[:apps]&.size&.to_s || "N/A"]
        ]

        table(%w[Check Status], rows)

        puts
        if checks[:ssh] && checks[:service] == "active" && checks[:api_health]
          ok "Tengu is healthy on #{@host_key}"
        elsif checks[:ssh]
          warn "Tengu has issues on #{@host_key}"
        else
          err "Cannot reach #{@host_key}"
        end
      end

      def run_ssh(cmd)
        `ssh -o ConnectTimeout=5 -o BatchMode=yes #{@host[:ssh]} '#{cmd}' 2>/dev/null`
      end
    end
  end
end
