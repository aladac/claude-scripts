#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiCheck < Claude::Generator
  METADATA = { name: "ratatui:check", desc: "Check RatatuiRuby gem status" }.freeze

  def execute
    section "RatatuiRuby Status"

    check_ruby_version
    check_gem_installed
    check_latest_version
    smoke_test
  end

  private

  def check_ruby_version
    version = `ruby --version 2>/dev/null`.strip
    match = version.match(/ruby (\d+\.\d+)/)
    if match
      major_minor = match[1].to_f
      if major_minor >= 3.2
        ok "Ruby #{match[1]} (requires 3.2+)"
      else
        err "Ruby #{match[1]} - too old (requires 3.2+)"
      end
    else
      err "Could not detect Ruby version"
    end
  end

  def check_gem_installed
    puts
    bold "Gem Installation"

    output = `gem list ratatui_ruby 2>/dev/null`.strip
    if output.include?("ratatui_ruby")
      match = output.match(/\(([^)]+)\)/)
      version = match ? match[1] : "unknown"
      ok "Installed: #{version}"
      @installed_version = version
    else
      err "Not installed"
      info "Install with: gem install ratatui_ruby"
      @installed_version = nil
    end
  end

  def check_latest_version
    puts
    bold "Latest Version"

    latest = `gem search ratatui_ruby --remote 2>/dev/null`.strip
    match = latest.match(/\(([^)]+)\)/)
    if match
      version = match[1]
      if @installed_version == version
        ok "#{version} (up to date)"
      elsif @installed_version
        warn "#{version} available (you have #{@installed_version})"
        info "Update with: gem update ratatui_ruby"
      else
        info "Latest: #{version}"
      end
    else
      muted "Could not check remote version"
    end
  end

  def smoke_test
    return unless @installed_version

    puts
    bold "Quick Test"

    result = `ruby -e "require 'ratatui_ruby'; puts RatatuiRuby::VERSION" 2>&1`
    if $?.success?
      ok "Loads successfully (#{result.strip})"
    else
      err "Failed to load"
      info result.lines.first.strip if result.lines.any?
    end
  end
end

RatatuiCheck.run
