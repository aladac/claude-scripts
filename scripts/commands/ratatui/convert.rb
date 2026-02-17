#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiConvert < Claude::Generator
  METADATA = { name: "ratatui:convert", desc: "Analyze CLI script for TUI conversion" }.freeze

  def execute
    file = args.first

    if file.nil? || file.empty?
      show_usage
      return
    end

    path = File.expand_path(file)
    unless File.exist?(path)
      err "File not found: #{path}"
      return
    end

    analyze(path)
  end

  private

  def show_usage
    section "CLI to TUI Converter"

    info "Analyzes a Ruby CLI script and suggests TUI structure."
    puts
    bold "Usage:"
    info "  /ratatui:convert <file.rb>"
    puts
    bold "What it does:"
    info "  1. Reads the script"
    info "  2. Identifies outputs (puts, print, pp)"
    info "  3. Identifies inputs (gets, ARGV, options)"
    info "  4. Suggests widget mapping"
    info "  5. Generates scaffold recommendation"
  end

  def analyze(path)
    content = File.read(path)
    lines = content.lines

    section "Analyzing: #{File.basename(path)}"
    info "#{lines.size} lines"

    puts
    analysis = {
      outputs: find_outputs(content),
      inputs: find_inputs(content),
      loops: find_loops(content),
      classes: find_classes(content),
      methods: find_methods(content)
    }

    report_outputs(analysis[:outputs])
    report_inputs(analysis[:inputs])
    report_structure(analysis)
    suggest_widgets(analysis)
    generate_recommendation(path, analysis)
  end

  def find_outputs(content)
    {
      puts: content.scan(/\bputs\b/).size,
      print: content.scan(/\bprint\b/).size,
      pp: content.scan(/\bpp\b/).size,
      printf: content.scan(/\bprintf\b/).size,
      tables: content.scan(/TTY::Table|terminal-table|hirb/).size > 0,
      progress: content.scan(/TTY::ProgressBar|ProgressBar|spinner/i).size > 0,
      colors: content.scan(/CLI::UI|pastel|rainbow|colorize/i).size > 0
    }
  end

  def find_inputs(content)
    {
      gets: content.scan(/\bgets\b/).size,
      argv: content.scan(/\bARGV\b/).size,
      stdin: content.scan(/\$stdin|\bSTDIN\b/).size,
      optparse: content.include?("OptionParser") || content.include?("optparse"),
      thor: content.include?("Thor"),
      tty_prompt: content.include?("TTY::Prompt"),
      readline: content.include?("Readline")
    }
  end

  def find_loops(content)
    {
      loop: content.scan(/\bloop\s+do\b/).size,
      while: content.scan(/\bwhile\b/).size,
      each: content.scan(/\.each\b/).size,
      map: content.scan(/\.map\b/).size
    }
  end

  def find_classes(content)
    content.scan(/^\s*class\s+(\w+)/).flatten
  end

  def find_methods(content)
    content.scan(/^\s*def\s+(\w+)/).flatten
  end

  def report_outputs(outputs)
    puts
    bold "Outputs Detected"

    total = outputs[:puts] + outputs[:print] + outputs[:pp] + outputs[:printf]
    info "  Print statements: #{total}"
    info "  Tables: #{outputs[:tables] ? 'Yes' : 'No'}"
    info "  Progress bars: #{outputs[:progress] ? 'Yes' : 'No'}"
    info "  Colors: #{outputs[:colors] ? 'Yes' : 'No'}"
  end

  def report_inputs(inputs)
    puts
    bold "Inputs Detected"

    info "  gets calls: #{inputs[:gets]}"
    info "  ARGV usage: #{inputs[:argv] > 0 ? 'Yes' : 'No'}"
    info "  OptionParser: #{inputs[:optparse] ? 'Yes' : 'No'}"
    info "  Thor CLI: #{inputs[:thor] ? 'Yes' : 'No'}"
    info "  TTY::Prompt: #{inputs[:tty_prompt] ? 'Yes' : 'No'}"
  end

  def report_structure(analysis)
    puts
    bold "Structure"

    info "  Classes: #{analysis[:classes].join(', ')}" if analysis[:classes].any?
    info "  Methods: #{analysis[:methods].size}"
    info "  Loops: #{analysis[:loops].values.sum}"
  end

  def suggest_widgets(analysis)
    puts
    bold "Suggested Widgets"

    suggestions = []

    outputs = analysis[:outputs]
    inputs = analysis[:inputs]

    # Based on outputs
    if outputs[:tables]
      suggestions << ["Table", "Replace TTY::Table with tui.table()"]
    end

    if outputs[:progress]
      suggestions << ["Gauge/LineGauge", "Replace progress bars with tui.gauge()"]
    end

    if outputs[:puts] > 10
      suggestions << ["Paragraph", "Consolidate output into Paragraph widgets"]
    end

    # Based on inputs
    if inputs[:gets] > 0 || inputs[:tty_prompt]
      suggestions << ["TextInput", "Use /ratatui:snippet input for text entry"]
    end

    if inputs[:optparse] || inputs[:thor] || inputs[:argv] > 0
      suggestions << ["CommandPalette", "Use /ratatui:component command_palette"]
    end

    # Based on structure
    if analysis[:loops][:loop] > 0 || analysis[:loops][:while] > 0
      suggestions << ["Event Loop", "Already has loop structure - adapt to TUI event loop"]
    end

    if suggestions.empty?
      suggestions << ["Paragraph", "Basic text display"]
      suggestions << ["Block", "Container with borders"]
    end

    suggestions.each do |widget, reason|
      info "  #{widget}: #{reason}"
    end
  end

  def generate_recommendation(path, analysis)
    puts
    bold "Recommended Approach"
    hr

    basename = File.basename(path, ".rb")

    if analysis[:outputs][:tables]
      puts <<~TEXT
        This script uses tables. Consider a list-based TUI:

          /ratatui:scaffold #{basename}_tui list

        Then:
        1. Convert table data to list items
        2. Add Table widget for detailed view
        3. Add keyboard navigation (j/k/Enter)

      TEXT
    elsif analysis[:loops][:loop] > 0
      puts <<~TEXT
        This script has a main loop. Good candidate for TUI:

          /ratatui:scaffold #{basename}_tui dashboard

        Then:
        1. Move loop logic to event handler
        2. Convert prints to widget renders
        3. Add status bar for current state

      TEXT
    elsif analysis[:outputs][:progress]
      puts <<~TEXT
        This script has progress indicators. Use inline viewport:

          /ratatui:scaffold #{basename}_tui basic

        Add to run method:
          RatatuiRuby.run(viewport: :inline, height: 5) do |tui|
            # Progress display
          end

      TEXT
    else
      puts <<~TEXT
        Standard CLI script. Start with basic scaffold:

          /ratatui:scaffold #{basename}_tui basic

        Then:
        1. Identify main output → Paragraph widget
        2. Add Block containers for sections
        3. Add keyboard shortcuts for actions

      TEXT
    end

    puts "Run /ratatui:docs all to load full documentation."
  end
end

RatatuiConvert.run
