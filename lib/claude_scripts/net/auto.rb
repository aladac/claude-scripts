# frozen_string_literal: true

module ClaudeScripts
  module Net
    class Auto < Command
      TEST_IPS = %w[8.8.8.8 1.1.1.1].freeze

      def run
        current = detect_mode
        puts "Current mode: #{current}"

        case current
        when "wifi"
          if wifi_has_internet?
            ok "WiFi has internet, no action needed"
          else
            warn "WiFi down! Switching to split..."
            Switch.call(["split"])
          end
        else
          system("sudo", "networksetup", "-setairportpower", "en0", "on", out: File::NULL, err: File::NULL)
          sleep 2

          if wifi_has_internet?
            ok "WiFi recovered!"
            Switch.call(["wifi"])
          else
            warn "WiFi still down, staying on iPhone"
          end
        end
      end

      private

      def detect_mode
        iface = `route -n get default 2>/dev/null`[/interface:\s+(\S+)/, 1] || "none"
        wifi_on = `networksetup -getairportpower en0 2>/dev/null`.include?("On")
        iface == "en7" ? (wifi_on ? "split" : "iphone") : "wifi"
      end

      def wifi_has_internet?
        wifi_gw = `networksetup -getinfo Wi-Fi 2>/dev/null`[/^Router:\s+(\S+)/, 1]
        return false unless wifi_gw && wifi_gw != "none"
        return false unless system("ping", "-c", "1", "-t", "2", wifi_gw, out: File::NULL, err: File::NULL)

        TEST_IPS.each { |ip| system("sudo", "route", "-n", "delete", ip, out: File::NULL, err: File::NULL) }
        TEST_IPS.each { |ip| system("sudo", "route", "-n", "add", ip, wifi_gw, out: File::NULL, err: File::NULL) }

        result = TEST_IPS.any? { |ip| system("ping", "-c", "2", "-t", "3", ip, out: File::NULL, err: File::NULL) }

        TEST_IPS.each { |ip| system("sudo", "route", "-n", "delete", ip, out: File::NULL, err: File::NULL) }
        result
      end
    end
  end
end
