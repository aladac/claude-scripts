# frozen_string_literal: true

module ClaudeScripts
  module AI
    module SD
      class Models < Command
        def run
          title "SD Models on Junkpile"

          puts
          info "Checkpoints"
          puts `ssh junkpile 'ls -1 /var/lib/tensors/models/checkpoints/*.gguf 2>/dev/null' | xargs -I{} basename {}`

          puts
          info "LoRAs"
          puts `ssh junkpile 'ls -1 /var/lib/tensors/models/loras/*.gguf 2>/dev/null' | xargs -I{} basename {}`
        end
      end
    end
  end
end
