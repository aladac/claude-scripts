# frozen_string_literal: true

module Jikko
  module Util
    module Sync
      class Config < Command
        HOST = "chi@junkpile"
        FILES = %w[.gemrc .gitignore .gitconfig .zshrc].freeze

        def run
          title "Syncing to #{HOST}"

          FILES.each do |file|
            local = File.expand_path("~/#{file}")
            if File.exist?(local)
              spin("#{file}") { system("scp", "-q", local, "#{HOST}:~/#{file}", out: File::NULL) }
            else
              warn "#{file} (not found)"
            end
          end

          ok "Done"
        end
      end
    end
  end
end
