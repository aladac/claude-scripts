# frozen_string_literal: true

module Jikko
  module AI
    module SD
      class Convert < Command
        def run
          model = args.first
          unless model
            err "Usage: jikko ai sd convert <model> [--type q8_0]"
            return
          end

          type = args.include?("--type") ? args[args.index("--type") + 1] : "q8_0"

          title "Convert to GGUF"
          puts "Model: #{model}"
          puts "Type:  #{type}"
          puts

          spin("Converting on junkpile") do
            system("ssh", "junkpile", "tsr convert #{model} --type #{type}", out: File::NULL)
          end

          ok "Conversion complete"
        end
      end
    end
  end
end
