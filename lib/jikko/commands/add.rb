# frozen_string_literal: true

require_relative "init"

module Jikko
  module Commands
    class Add < Command
      def run
        category, name, *desc_parts = args
        desc = desc_parts.join(" ")

        unless category && name
          err "Usage: jikko commands add <category> <name> [description...]"
          return
        end

        desc = "TODO" if desc.empty?

        # Run init to create scaffold
        init = Init.new([category, name, desc])
        init.run

        # Output marker for agent instructions
        puts "---"
        puts "SCAFFOLD_CREATED=true"
        puts "DESCRIPTION=#{desc}"
      end
    end
  end
end
