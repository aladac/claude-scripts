# frozen_string_literal: true

module Jikko
  class Bump < Command
    PROJECT_TYPES = {
      rust: { file: "Cargo.toml", pattern: /^version = "(.+?)"/m },
      python: { file: "pyproject.toml", pattern: /^version = "(.+?)"/m },
      node: { file: "package.json", pattern: /"version":\s*"(.+?)"/ },
      ruby: { file: "lib/**/version.rb", pattern: /VERSION\s*=\s*["'](.+?)["']/ }
    }.freeze

    def run
      @bump_type = args.first&.sub(/^--/, "")
      @dry_run = args.include?("--dry-run")
      @no_git = args.include?("--no-git")

      detect_project
      @current = read_version
      @new = calculate_new

      show_preview
      return if @dry_run

      update_files
      git_ops unless @no_git

      puts
      ok "#{@current} -> #{@new}"
    end

    private

    def detect_project
      PROJECT_TYPES.each do |type, cfg|
        file = cfg[:file]
        if file.include?("*")
          matches = Dir.glob(file)
          if matches.any?
            @type = type
            @file = matches.first
            return
          end
        elsif File.exist?(file)
          @type = type
          @file = file
          return
        end
      end

      err "No supported project found"
      exit 1
    end

    def read_version
      content = File.read(@file)
      match = content.match(PROJECT_TYPES[@type][:pattern])
      match ? match[1] : (err("Version not found") || exit(1))
    end

    def calculate_new
      major, minor, patch = @current.split(".").map(&:to_i)

      case @bump_type
      when "major" then "#{major + 1}.0.0"
      when "minor" then "#{major}.#{minor + 1}.0"
      when "patch" then "#{major}.#{minor}.#{patch + 1}"
      else "#{major}.#{minor}.#{patch + 1}" # default to patch
      end
    end

    def show_preview
      frame "Version Bump" do
        puts "Project:  #{@type} (#{@file})"
        puts "Current:  #{@current}"
        puts "New:      #{@new}"
        puts "Type:     #{@bump_type || 'patch'}"
        puts "(dry run)" if @dry_run
      end
    end

    def update_files
      spin("Updating #{@file}") do
        content = File.read(@file)
        new_content = content.sub(PROJECT_TYPES[@type][:pattern]) { |m| m.sub(@current, @new) }
        File.write(@file, new_content)
      end
    end

    def git_ops
      spin("Committing") do
        system("git", "add", @file, out: File::NULL)
        system("git", "commit", "-m", @new, out: File::NULL)
      end

      spin("Tagging v#{@new}") do
        system("git", "tag", "-a", "v#{@new}", "-m", "v#{@new}", out: File::NULL)
      end
    end
  end
end
