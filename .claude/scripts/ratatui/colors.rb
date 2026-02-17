#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiColors < Claude::Generator
  METADATA = { name: "ratatui:colors", desc: "Color palette reference" }.freeze

  NAMED_COLORS = {
    "Basic" => %i[black red green yellow blue magenta cyan gray white],
    "Light" => %i[dark_gray light_red light_green light_yellow light_blue light_magenta light_cyan]
  }.freeze

  ANSI_256_SAMPLES = [
    [16, "black"],
    [196, "red"],
    [46, "green"],
    [226, "yellow"],
    [21, "blue"],
    [201, "magenta"],
    [51, "cyan"],
    [231, "white"],
    [240, "gray"]
  ].freeze

  SCHEMES = {
    "gruvbox" => {
      bg: "#282828", fg: "#ebdbb2",
      red: "#cc241d", green: "#98971a", yellow: "#d79921",
      blue: "#458588", magenta: "#b16286", cyan: "#689d6a"
    },
    "dracula" => {
      bg: "#282a36", fg: "#f8f8f2",
      red: "#ff5555", green: "#50fa7b", yellow: "#f1fa8c",
      blue: "#6272a4", magenta: "#ff79c6", cyan: "#8be9fd"
    },
    "nord" => {
      bg: "#2e3440", fg: "#eceff4",
      red: "#bf616a", green: "#a3be8c", yellow: "#ebcb8b",
      blue: "#5e81ac", magenta: "#b48ead", cyan: "#88c0d0"
    },
    "tokyo-night" => {
      bg: "#1a1b26", fg: "#c0caf5",
      red: "#f7768e", green: "#9ece6a", yellow: "#e0af68",
      blue: "#7aa2f7", magenta: "#bb9af7", cyan: "#7dcfff"
    }
  }.freeze

  def execute
    topic = args.first&.downcase

    case topic
    when nil, ""
      show_all
    when "named"
      show_named
    when "256"
      show_256
    when "schemes"
      show_schemes
    when *SCHEMES.keys
      show_scheme(topic)
    else
      err "Unknown topic: #{topic}"
      puts
      info "Usage: /ratatui:colors [named|256|schemes|<scheme-name>]"
    end
  end

  private

  def show_all
    section "RatatuiRuby Colors"

    show_named
    puts
    show_256_summary
    puts
    show_schemes_summary
  end

  def show_named
    bold "Named Colors"
    puts
    NAMED_COLORS.each do |group, colors|
      puts "  #{group}:"
      colors.each do |c|
        code = color_code(c)
        print "    \e[#{code}m■\e[0m :#{c}"
        puts
      end
    end
    puts
    info "Usage: Style.new(fg: :red, bg: :black)"
  end

  def show_256_summary
    bold "256-Color Palette (samples)"
    puts
    ANSI_256_SAMPLES.each do |num, name|
      print "  \e[38;5;#{num}m■\e[0m #{num.to_s.ljust(4)} #{name}"
      puts
    end
    puts
    info "Usage: Style.new(fg: 196)  # bright red"
    info "Run /ratatui:colors 256 for full palette"
  end

  def show_256
    bold "256-Color Palette"
    puts

    # Standard colors 0-15
    puts "  Standard (0-15):"
    print "  "
    (0..15).each { |i| print "\e[48;5;#{i}m  \e[0m" }
    puts
    puts

    # Color cube 16-231
    puts "  Color Cube (16-231):"
    (0..5).each do |g|
      print "  "
      (0..5).each do |r|
        (0..5).each do |b|
          code = 16 + (r * 36) + (g * 6) + b
          print "\e[48;5;#{code}m  \e[0m"
        end
        print " "
      end
      puts
    end
    puts

    # Grayscale 232-255
    puts "  Grayscale (232-255):"
    print "  "
    (232..255).each { |i| print "\e[48;5;#{i}m  \e[0m" }
    puts
  end

  def show_schemes_summary
    bold "Color Schemes"
    SCHEMES.each_key { |name| info "  #{name}" }
    puts
    info "Run /ratatui:colors <scheme-name> for details"
  end

  def show_schemes
    section "Color Schemes"

    SCHEMES.each do |name, colors|
      puts
      bold name
      colors.each do |key, hex|
        r, g, b = hex_to_rgb(hex)
        print "  \e[48;2;#{r};#{g};#{b}m    \e[0m #{key}: #{hex}"
        puts
      end
    end
  end

  def show_scheme(name)
    colors = SCHEMES[name]
    section "#{name} Color Scheme"

    colors.each do |key, hex|
      r, g, b = hex_to_rgb(hex)
      print "\e[48;2;#{r};#{g};#{b}m    \e[0m #{key.to_s.ljust(10)} #{hex}"
      puts
    end

    puts
    bold "Usage:"
    puts <<~RUBY
      COLORS = {
        bg: "#{colors[:bg]}",
        fg: "#{colors[:fg]}",
        red: "#{colors[:red]}",
        green: "#{colors[:green]}"
      }

      Style.new(fg: COLORS[:red], bg: COLORS[:bg])
    RUBY
  end

  def color_code(sym)
    codes = {
      black: 30, red: 31, green: 32, yellow: 33,
      blue: 34, magenta: 35, cyan: 36, gray: 37, white: 97,
      dark_gray: 90, light_red: 91, light_green: 92, light_yellow: 93,
      light_blue: 94, light_magenta: 95, light_cyan: 96
    }
    codes[sym] || 37
  end

  def hex_to_rgb(hex)
    hex = hex.delete("#")
    [hex[0..1], hex[2..3], hex[4..5]].map { |c| c.to_i(16) }
  end
end

RatatuiColors.run
