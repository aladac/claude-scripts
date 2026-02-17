#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiSymbols < Claude::Generator
  METADATA = { name: "ratatui:symbols", desc: "Unicode symbols reference for TUIs" }.freeze

  CATEGORIES = {
    "box" => {
      name: "Box Drawing",
      symbols: {
        "Light" => "─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼",
        "Heavy" => "━ ┃ ┏ ┓ ┗ ┛ ┣ ┫ ┳ ┻ ╋",
        "Double" => "═ ║ ╔ ╗ ╚ ╝ ╠ ╣ ╦ ╩ ╬",
        "Rounded" => "╭ ╮ ╯ ╰",
        "Dashed" => "┄ ┅ ┆ ┇ ┈ ┉ ┊ ┋"
      }
    },
    "blocks" => {
      name: "Block Elements",
      symbols: {
        "Full/Partial" => "█ ▓ ▒ ░",
        "Halves" => "▀ ▄ ▌ ▐",
        "Quadrants" => "▖ ▗ ▘ ▙ ▚ ▛ ▜ ▝ ▞ ▟",
        "Eighths H" => "▏ ▎ ▍ ▌ ▋ ▊ ▉ █",
        "Eighths V" => "▁ ▂ ▃ ▄ ▅ ▆ ▇ █"
      }
    },
    "progress" => {
      name: "Progress & Bars",
      symbols: {
        "Horizontal" => "━ ─ ▬ ▭ ▮ ▯",
        "Circles" => "○ ◔ ◑ ◕ ● ◐ ◒ ◓",
        "Squares" => "□ ◻ ◼ ■ ▢ ▣",
        "Braille" => "⠀ ⠁ ⠉ ⠛ ⠿ ⣿",
        "Spinner" => "◴ ◷ ◶ ◵  |  ◐ ◓ ◑ ◒  |  ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
      }
    },
    "arrows" => {
      name: "Arrows & Pointers",
      symbols: {
        "Simple" => "← → ↑ ↓ ↔ ↕",
        "Double" => "⇐ ⇒ ⇑ ⇓ ⇔ ⇕",
        "Triangles" => "▲ ▼ ◀ ▶ △ ▽ ◁ ▷",
        "Pointers" => "› ‹ » « ▸ ◂ ▴ ▾",
        "Chevrons" => "‹ › « » ⟨ ⟩ ⟪ ⟫"
      }
    },
    "status" => {
      name: "Status Icons",
      symbols: {
        "Checkmarks" => "✓ ✔ ☑ ✗ ✘ ☒ ⊠",
        "Circles" => "● ○ ◉ ◌ ◎ ⊙ ⊚",
        "States" => "⏳ ⌛ ⏸ ▶ ⏹ ⏺ ⏭ ⏮",
        "Info" => "ℹ ⚠ ⛔ ✱ ✲ ✳ ✴ ✵",
        "Stars" => "★ ☆ ✦ ✧ ✩ ✪ ✫ ✬"
      }
    },
    "misc" => {
      name: "Miscellaneous",
      symbols: {
        "Dots" => "· • ‥ … ⁘ ⁙ ⁚",
        "Math" => "± × ÷ ≠ ≤ ≥ ≈ ∞",
        "Brackets" => "⌈ ⌉ ⌊ ⌋ ⎡ ⎤ ⎣ ⎦",
        "Misc" => "§ ¶ † ‡ ※ ⁂ ☰ ☱ ☲",
        "Lines" => "╱ ╲ ╳ ⁄ ∕ ╌ ╍ ╎ ╏"
      }
    }
  }.freeze

  def execute
    category = args.first&.downcase

    if category.nil? || category.empty?
      show_all
    elsif CATEGORIES.key?(category)
      show_category(category)
    else
      err "Unknown category: #{category}"
      puts
      list_categories
    end
  end

  private

  def list_categories
    bold "Available categories:"
    CATEGORIES.each { |key, cat| info "  #{key} - #{cat[:name]}" }
  end

  def show_all
    section "Unicode Symbols for TUIs"

    CATEGORIES.each do |_key, cat|
      puts
      bold cat[:name]
      cat[:symbols].each do |label, syms|
        puts "  #{label.ljust(12)} #{syms}"
      end
    end

    puts
    hr
    info "Usage: /ratatui:symbols [category]"
    info "Categories: #{CATEGORIES.keys.join(', ')}"
  end

  def show_category(key)
    cat = CATEGORIES[key]
    section cat[:name]

    cat[:symbols].each do |label, syms|
      bold label
      puts "  #{syms}"
      puts
    end
  end
end

RatatuiSymbols.run
