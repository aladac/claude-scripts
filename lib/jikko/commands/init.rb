# frozen_string_literal: true

module Jikko
  module Commands
    class Init < Command
      REPO_ROOT = File.expand_path("~/Projects/claude-scripts")
      LIB_DIR = File.join(REPO_ROOT, "lib", "jikko")
      COMMANDS_DIR = File.join(REPO_ROOT, "commands")

      ACRONYMS = %w[ai sd api ui cf cl ps psn].freeze

      def run
        category, name, desc = args[0], args[1], args[2] || "TODO"

        unless category && name
          err "Usage: jikko commands init <category> <name> [description]"
          return
        end

        # Paths for Ruby class and markdown skill
        rb_dir = File.join(LIB_DIR, category)
        rb_file = File.join(rb_dir, "#{name}.rb")
        md_dir = File.join(COMMANDS_DIR, category)
        md_file = File.join(md_dir, "#{name}.md")

        if File.exist?(rb_file)
          err "Ruby class already exists: #{home(rb_file)}"
          return
        end

        if File.exist?(md_file)
          err "Skill file already exists: #{home(md_file)}"
          return
        end

        # Generate module/class names
        modules = category.split("/").map { |p| camelize(p) }
        class_name = camelize(name)
        cli_cmd = "#{category.tr('/', ' ')} #{name}"

        # Create Ruby class file
        FileUtils.mkdir_p(rb_dir)
        File.write(rb_file, generate_rb(modules, class_name))
        ok "Created: #{home(rb_file)}"

        # Create markdown skill file
        FileUtils.mkdir_p(md_dir)
        File.write(md_file, generate_md(desc, cli_cmd))
        ok "Created: #{home(md_file)}"

        info "Usage: /#{category.tr('/', ':')}:#{name}"
        info "Rebuild gem: gem build jikko.gemspec && gem install jikko-*.gem"

        # Output paths for agent use
        puts "---"
        puts "RUBY_FILE=#{rb_file}"
        puts "MD_FILE=#{md_file}"
      end

      private

      def camelize(str)
        return str.upcase if ACRONYMS.include?(str.downcase)
        str.split(/[_-]/).map(&:capitalize).join
      end

      def generate_rb(modules, class_name)
        indent = "  "
        lines = ["# frozen_string_literal: true", ""]
        lines << "module Jikko"

        modules.each_with_index do |mod, i|
          lines << "#{indent * (i + 1)}module #{mod}"
        end

        class_indent = indent * (modules.size + 1)
        lines << "#{class_indent}class #{class_name} < Command"
        lines << "#{class_indent}  def run"
        lines << "#{class_indent}    # TODO: implement"
        lines << "#{class_indent}    info \"Not implemented yet\""
        lines << "#{class_indent}  end"
        lines << "#{class_indent}end"

        modules.size.downto(0) do |i|
          lines << "#{indent * i}end"
        end

        lines.join("\n") + "\n"
      end

      def generate_md(desc, cli_cmd)
        <<~MD
          ---
          description: #{desc}
          ---
          ```bash
          jikko #{cli_cmd} $ARGUMENTS
          ```
        MD
      end
    end
  end
end
