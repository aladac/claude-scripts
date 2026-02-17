#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiCheck < Claude::Generator
  METADATA = { name: "ratatui:check", desc: "Check Ratatui setup in Cargo.toml" }.freeze

  def execute
    section "Ratatui Setup Check"

    cargo_toml = find_cargo_toml
    if cargo_toml.nil?
      err "No Cargo.toml found in current directory or parents"
      puts
      info "Create a new Rust project with: cargo new my_tui_app"
      return
    end

    ok "Found: #{home_path(cargo_toml)}"

    content = File.read(cargo_toml)
    check_dependencies(content)
  end

  private

  def find_cargo_toml
    dir = Dir.pwd
    loop do
      path = File.join(dir, "Cargo.toml")
      return path if File.exist?(path)

      parent = File.dirname(dir)
      return nil if parent == dir

      dir = parent
    end
  end

  def check_dependencies(content)
    puts

    # Check ratatui
    if content =~ /ratatui\s*=\s*["']?([^"'\s,}]+)/
      version = ::Regexp.last_match(1)
      ok "ratatui = #{version}"
      check_version("ratatui", version, "0.29")
    else
      err "ratatui not found in dependencies"
      puts
      info "Add to Cargo.toml:"
      puts '  ratatui = "0.29"'
    end

    # Check crossterm
    if content =~ /crossterm\s*=\s*["']?([^"'\s,}]+)/
      version = ::Regexp.last_match(1)
      ok "crossterm = #{version}"
      check_version("crossterm", version, "0.28")
    else
      err "crossterm not found in dependencies"
      puts
      info "Add to Cargo.toml:"
      puts '  crossterm = "0.28"'
    end

    # Check tokio (optional for async)
    if content =~ /tokio\s*=/
      ok "tokio found (async support)"
    else
      muted "tokio not found (optional, for async)"
    end

    puts
    info "Latest versions: ratatui 0.29, crossterm 0.28"
  end

  def check_version(name, current, recommended)
    current_parts = current.delete('"').split(".").map(&:to_i)
    recommended_parts = recommended.split(".").map(&:to_i)

    if current_parts[0] < recommended_parts[0] ||
       (current_parts[0] == recommended_parts[0] && current_parts[1] < recommended_parts[1])
      warn "  Consider upgrading #{name} to #{recommended}+"
    end
  rescue StandardError
    # Ignore version parse errors
  end
end

RatatuiCheck.run
