# frozen_string_literal: true

module ClaudeScripts
  module CF
    class Dns < Command
      CMDS = %w[zones list find add update delete].freeze

      def run
        cmd = args.shift
        unless CMDS.include?(cmd)
          puts "Usage: claude-scripts cf dns <command>"
          puts "Commands: #{CMDS.join(', ')}"
          return
        end
        send("cmd_#{cmd}")
      end

      private

      def cmd_zones = sh "flarectl zone list"

      def cmd_list
        zone = args.shift || return err("Missing zone")
        sh "flarectl dns list --zone #{zone}"
      end

      def cmd_find
        zone, name = args.shift(2)
        output = `flarectl dns list --zone "#{zone}" 2>&1`
        matches = output.lines.select { |l| l.downcase.include?(name.downcase) }
        matches.empty? ? muted("No matches") : matches.each { |l| puts l }
      end

      def cmd_add
        zone, type, name, content = args.shift(4)
        proxy = args.include?("--proxy") ? "--proxy" : ""
        sh "flarectl dns create --zone #{zone} --type #{type} --name #{name} --content #{content} #{proxy}"
      end

      def cmd_update
        zone, id, content = args.shift(3)
        proxy = args.include?("--proxy") ? "--proxy" : ""
        sh "flarectl dns update --zone #{zone} --id #{id} --content #{content} #{proxy}"
      end

      def cmd_delete
        zone, id = args.shift(2)
        sh "flarectl dns delete --zone #{zone} --id #{id}"
      end
    end
  end
end
