# frozen_string_literal: true

module Jikko
  module Tengu
    class Init < Command
      DIR = File.expand_path("~/Projects/tengu-init")

      def run
        unless Dir.exist?(DIR)
          err "Not found: #{DIR}"
          return
        end

        Dir.chdir(DIR) do
          local = `cargo pkgid 2>/dev/null`.strip.split("#").last
          installed = `tengu-init --version 2>/dev/null`.strip.split.last

          if local == installed
            ok "Up to date (#{installed})"
          else
            info "Local: #{local}, Installed: #{installed || 'none'}"
            spin("Building") { sh "cargo install --path .", capture: true }
            ok "Rebuilt"
          end
        end
      end
    end
  end
end
