# frozen_string_literal: true

module Jikko
  module AI
    module SD
      class Generate < Command
        def run
          prompt = args.reject { |a| a.start_with?("-") }.join(" ")

          if prompt.empty?
            err "Usage: jikko ai sd generate <prompt>"
            return
          end

          model = extract_opt("-m") || "obsessiveCompulsive_v20-q8_0.gguf"
          width = extract_opt("-W")&.to_i || 512
          height = extract_opt("-H")&.to_i || 512
          steps = extract_opt("--steps")&.to_i || 20
          cfg = extract_opt("--cfg")&.to_f || 6
          seed = extract_opt("-s")&.to_i || -1

          timestamp = Time.now.to_i
          filename = "sd_#{timestamp}.png"
          remote = "/var/lib/tensors/outputs/#{filename}"
          local_dir = File.expand_path("~/Projects/gallery/@output")
          FileUtils.mkdir_p(local_dir)
          local = "#{local_dir}/#{filename}"

          model_path = model.start_with?("/") ? model : "/var/lib/tensors/models/checkpoints/#{model}"
          negative = "worst quality, low quality, lowres"

          frame "SD Generate" do
            puts "Model:  #{model}"
            puts "Size:   #{width}x#{height}"
            puts "Steps:  #{steps}, CFG: #{cfg}"
            puts "Prompt: #{prompt[0, 60]}#{'...' if prompt.length > 60}"
          end

          puts
          spin("Generating on junkpile") do
            cmd = <<~CMD.gsub("\n", " ")
              ssh junkpile "HSA_OVERRIDE_GFX_VERSION=10.3.0 sd
              --model '#{model_path}'
              --prompt '#{prompt.gsub("'", "'\\''")}'
              -n '#{negative}'
              -W #{width} -H #{height}
              --steps #{steps} --cfg-scale #{cfg} -s #{seed}
              -o '#{remote}'"
            CMD
            system(cmd, out: File::NULL)
          end

          spin("Copying to local") do
            system("scp", "junkpile:#{remote}", local, out: File::NULL, err: File::NULL)
          end

          puts
          ok "Saved: #{local}"
        end

        private

        def extract_opt(flag)
          idx = args.index(flag)
          idx ? args[idx + 1] : nil
        end
      end
    end
  end
end
