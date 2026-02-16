# frozen_string_literal: true

module ClaudeScripts
  module Docker
    class Ps < Command
      def run
        output = `docker ps --format "{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" 2>/dev/null`

        rows = output.lines.map do |line|
          line.strip.split("\t")
        end

        if rows.empty?
          muted "No containers running"
        else
          table(%w[ID Image Status Names], rows)
        end
      end
    end
  end
end
