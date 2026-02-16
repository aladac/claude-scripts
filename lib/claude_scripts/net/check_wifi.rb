# frozen_string_literal: true

module ClaudeScripts
  module Net
    class CheckWifi < Command
      TEST_IPS = %w[8.8.8.8 1.1.1.1].freeze

      def run
        wifi_power = `networksetup -getairportpower en0 2>/dev/null`.split.last
        if wifi_power != "On"
          err "WiFi is disabled"
          return
        end

        wifi_info = `networksetup -getinfo Wi-Fi 2>/dev/null`
        wifi_gw = wifi_info[/^Router:\s+(\S+)/, 1]
        wifi_ip = wifi_info[/^IP address:\s+(\S+)/, 1]

        puts "Gateway: #{wifi_gw || 'none'}"
        puts "IP: #{wifi_ip || 'none'}"

        unless wifi_gw && wifi_gw != "none"
          err "No WiFi gateway"
          return
        end

        unless system("ping", "-c", "1", "-t", "2", wifi_gw, out: File::NULL, err: File::NULL)
          err "Cannot reach router"
          return
        end
        ok "Router reachable"

        # Test internet via WiFi route
        cleanup_routes
        TEST_IPS.each { |ip| system("sudo", "route", "-n", "add", ip, wifi_gw, out: File::NULL, err: File::NULL) }

        puts
        wifi_ok = TEST_IPS.any? do |ip|
          result = system("ping", "-c", "2", "-t", "3", ip, out: File::NULL, err: File::NULL)
          result ? ok("ping #{ip}") : err("ping #{ip} failed")
          result
        end

        cleanup_routes
        puts
        wifi_ok ? ok("WiFi has internet") : err("WiFi has NO internet")
      end

      private

      def cleanup_routes
        TEST_IPS.each { |ip| system("sudo", "route", "-n", "delete", ip, out: File::NULL, err: File::NULL) }
      end
    end
  end
end
