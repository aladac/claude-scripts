# frozen_string_literal: true

module ClaudeScripts
  module Browse
    class Update < Command
      PLUGIN = "browse"
      MARKETPLACE = "saiden"
      SOURCE = File.expand_path("~/Projects/claude-browse")

      def run
        title "Update Browse Plugin"

        update_source
        update_submodule
        update_cache
      end

      private

      def update_source
        info "Source repository"

        Dir.chdir(SOURCE) do
          if `git status --porcelain`.strip.length > 0
            count = `git status --porcelain`.lines.size
            spin("Committing #{count} files") do
              system("git", "add", "-A", out: File::NULL)
              system("git", "commit", "-m", "Update #{Time.now.strftime('%Y-%m-%d %H:%M')}", out: File::NULL)
            end
          end

          unpushed = `git log @{u}..HEAD --oneline 2>/dev/null`.lines.size
          if unpushed > 0
            spin("Pushing #{unpushed} commits") { system("git", "push", out: File::NULL) }
          else
            ok "Already up to date"
          end

          @commit = `git rev-parse --short HEAD`.strip
        end
      end

      def update_submodule
        puts
        info "Marketplace submodule"

        mp = "#{Dir.home}/.claude/plugins/marketplaces/#{MARKETPLACE}"
        unless Dir.exist?(mp)
          warn "Marketplace not installed"
          return
        end

        Dir.chdir("#{mp}/plugins/#{PLUGIN}") do
          system("git", "fetch", "origin", out: File::NULL, err: File::NULL)
          current = `git rev-parse --short HEAD`.strip
          latest = `git rev-parse --short origin/master`.strip

          if current != latest
            system("git", "checkout", "origin/master", out: File::NULL, err: File::NULL)
            ok "Updated: #{current} -> #{latest}"

            Dir.chdir(mp) do
              system("git", "add", "plugins/#{PLUGIN}", out: File::NULL)
              system("git", "commit", "-m", "Update #{PLUGIN} to #{latest}", out: File::NULL)
              system("git", "push", out: File::NULL)
            end
          else
            ok "At latest (#{current})"
          end
        end
      end

      def update_cache
        puts
        info "Marketplace cache"
        spin("Updating") do
          system("claude", "plugin", "marketplace", "update", MARKETPLACE, out: File::NULL, err: File::NULL)
        end
      end
    end
  end
end
