# frozen_string_literal: true

module ClaudeScripts
  module Browse
    class Reinstall < Command
      PLUGIN = "browse"
      MARKETPLACE = "saiden"
      MARKETPLACE_REPO = "saiden-dev/claude-plugins"
      SOURCE = File.expand_path("~/Projects/claude-browse")

      def run
        @scope = args.include?("--global") ? "user" : "project"

        title "Reinstall Browse Plugin"
        muted "Scope: #{@scope}"

        check_source
        uninstall
        remove_marketplace
        add_marketplace
        install
        verify
      end

      private

      def check_source
        info "Checking source"

        Dir.chdir(SOURCE) do
          if `git status --porcelain`.strip.length > 0
            err "Uncommitted changes in source"
            exit 1
          end

          unpushed = `git log @{u}..HEAD --oneline 2>/dev/null`.lines.size
          if unpushed > 0
            spin("Pushing") { system("git", "push", out: File::NULL) }
          end

          @version = read_json("package.json")&.dig("version")
          @commit = `git rev-parse --short HEAD`.strip
          ok "Source: v#{@version} (#{@commit})"
        end
      end

      def uninstall
        puts
        info "Uninstalling"

        if `claude plugin list --scope #{@scope} 2>/dev/null`.include?("#{PLUGIN}@#{MARKETPLACE}")
          spin("Uninstalling plugin") do
            system("claude", "plugin", "uninstall", "--scope", @scope, "#{PLUGIN}@#{MARKETPLACE}", out: File::NULL)
          end
        end

        cache = "#{Dir.home}/.claude/plugins/cache/#{MARKETPLACE}"
        FileUtils.rm_rf(cache) if Dir.exist?(cache)
      end

      def remove_marketplace
        puts
        info "Removing marketplace"

        if `claude plugin marketplace list 2>/dev/null`.include?(MARKETPLACE)
          spin("Removing") { system("claude", "plugin", "marketplace", "remove", MARKETPLACE, out: File::NULL) }
        end

        mp = "#{Dir.home}/.claude/plugins/marketplaces/#{MARKETPLACE}"
        FileUtils.rm_rf(mp) if Dir.exist?(mp)
      end

      def add_marketplace
        puts
        info "Adding marketplace"
        spin("Adding #{MARKETPLACE_REPO}") do
          system("claude", "plugin", "marketplace", "add", MARKETPLACE_REPO, out: File::NULL)
        end
      end

      def install
        puts
        info "Installing plugin"
        spin("Installing #{PLUGIN}@#{MARKETPLACE}") do
          system("claude", "plugin", "install", "--scope", @scope, "#{PLUGIN}@#{MARKETPLACE}", out: File::NULL)
        end
      end

      def verify
        puts
        info "Verifying"

        json = "#{Dir.home}/.claude/plugins/installed_plugins.json"
        data = read_json(json)
        installed = data&.dig("plugins", "#{PLUGIN}@#{MARKETPLACE}", 0)

        if installed
          commit = installed["gitCommitSha"]&.[](0, 7)
          if commit == @commit
            ok "Verified: #{@commit}"
          else
            err "Commit mismatch: installed=#{commit}, source=#{@commit}"
          end
        else
          err "Plugin not found in registry"
        end
      end
    end
  end
end
