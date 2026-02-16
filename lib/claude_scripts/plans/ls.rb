# frozen_string_literal: true

module ClaudeScripts
  module Plans
    class Ls < Command
      PLANS_DIR = File.expand_path("~/.claude/plans")

      def run
        plans = Dir.glob("#{PLANS_DIR}/*.md").map do |path|
          content = File.read(path)
          {
            file: File.basename(path),
            title: content[/^# (.+)/, 1]&.sub(/^Plan: /, "") || "(untitled)",
            phases: content.scan(/^## Phase/).count,
            project: extract_project(content),
            modified: File.mtime(path)
          }
        end

        if plans.empty?
          muted "No plans found"
          return
        end

        plans.sort_by! { |p| -p[:modified].to_i }
        table(%w[Modified Project Title Phases], plans.map { |p|
          [p[:modified].strftime("%Y-%m-%d"), p[:project], p[:title][0, 40], p[:phases]]
        })
      end

      private

      def extract_project(content)
        content[%r{lib/([a-z_-]+)/}i, 1] ||
          content[%r{Projects/([a-z_-]+)/}i, 1] ||
          content[%r{src/([a-z_-]+)/}i, 1] || "-"
      end
    end
  end
end
