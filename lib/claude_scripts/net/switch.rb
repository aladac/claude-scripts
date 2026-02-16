# frozen_string_literal: true

module ClaudeScripts
  module Net
    class Switch < Command
      MODES = %w[wifi split iphone].freeze
      CYCLE = { "wifi" => "split", "split" => "iphone", "iphone" => "wifi" }.freeze

      def run
        current = detect_mode
        target = args.first || CYCLE[current]

        unless MODES.include?(target)
          err "Invalid mode: #{target}"
          puts "Usage: wifi, split, iphone, or no argument to cycle"
          return
        end

        apply_mode(target)
        sleep 1
        connectivity_test
      end

      private

      def detect_mode
        default_iface = `route -n get default 2>/dev/null`[/interface:\s+(\S+)/, 1] || "none"
        wifi_enabled = `networksetup -getairportpower en0 2>/dev/null`.include?("On")

        default_iface == "en7" ? (wifi_enabled ? "split" : "iphone") : "wifi"
      end

      def apply_mode(target)
        case target
        when "wifi"
          sh "sudo networksetup -setairportpower en0 on", capture: true
          sh "sudo networksetup -ordernetworkservices 'Wi-Fi' 'iPhone USB' 'Thunderbolt Bridge'"
          ok "MODE: wifi"
        when "split"
          sh "sudo networksetup -setairportpower en0 on", capture: true
          sh "sudo networksetup -ordernetworkservices 'iPhone USB' 'Wi-Fi' 'Thunderbolt Bridge'"
          ok "MODE: split"
        when "iphone"
          sh "sudo networksetup -ordernetworkservices 'iPhone USB' 'Wi-Fi' 'Thunderbolt Bridge'"
          sh "sudo networksetup -setairportpower en0 off", capture: true
          ok "MODE: iphone"
        end
      end

      def connectivity_test
        puts
        if system("ping", "-c", "1", "-t", "2", "8.8.8.8", out: File::NULL, err: File::NULL)
          ok "ping 8.8.8.8"
        else
          err "ping 8.8.8.8 failed"
        end

        ip = `curl -s --connect-timeout 3 https://api.ipify.org 2>/dev/null`.strip
        ip.empty? ? err("public_ip: failed") : ok("public_ip: #{ip}")
      end
    end
  end
end
