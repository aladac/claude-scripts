# frozen_string_literal: true

module Jikko
  module Util
    module Check
      class Plugin < Command
        PLUGIN = "browse"
        MARKETPLACE = "saiden"
        SOURCE = File.expand_path("~/Projects/claude-browse")

        def run
          title "Plugin: #{PLUGIN}@#{MARKETPLACE}"

          check_source
          check_installed
          check_sync
        end

        private

        def check_source
          return unless Dir.exist?(SOURCE)

          Dir.chdir(SOURCE) do
            @src_commit = `git rev-parse --short HEAD`.strip
            @src_version = read_json("package.json")&.dig("version")
            dirty = `git status --porcelain`.lines.size

            info "Source"
            puts "  Version: #{@src_version}"
            puts "  Commit:  #{@src_commit}"
            dirty > 0 ? warn("  #{dirty} uncommitted") : ok("  Clean")
          end
        end

        def check_installed
          puts
          info "Installed"

          json = "#{Dir.home}/.claude/plugins/installed_plugins.json"
          return muted("  Not found") unless File.exist?(json)

          data = read_json(json)
          plugin = data&.dig("plugins", "#{PLUGIN}@#{MARKETPLACE}", 0)
          return muted("  Not installed") unless plugin

          @inst_commit = plugin["gitCommitSha"]&.[](0, 7)
          @inst_version = plugin["version"]

          puts "  Version: #{@inst_version}"
          puts "  Commit:  #{@inst_commit}"
        end

        def check_sync
          puts
          return unless @src_commit && @inst_commit

          if @src_commit == @inst_commit
            ok "In sync (#{@src_commit})"
          else
            err "Out of sync: source=#{@src_commit}, installed=#{@inst_commit}"
          end
        end
      end
    end
  end
end
