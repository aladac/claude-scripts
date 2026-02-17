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

    info "Analyzes a Rust CLI program and suggests TUI structure."
    puts
    bold "Usage:"
    info "  /ratatui:convert <file.rs>"
    puts
    bold "What it does:"
    info "  1. Reads the source file"
    info "  2. Identifies outputs (println!, print!, eprintln!)"
    info "  3. Identifies inputs (stdin, args, clap)"
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
      structs: find_structs(content),
      functions: find_functions(content)
    }

    report_outputs(analysis[:outputs])
    report_inputs(analysis[:inputs])
    report_structure(analysis)
    suggest_widgets(analysis)
    generate_recommendation(path, analysis)
  end

  def find_outputs(content)
    {
      println: content.scan(/\bprintln!\b/).size,
      print: content.scan(/\bprint!\b/).size,
      eprintln: content.scan(/\beprintln!\b/).size,
      writeln: content.scan(/\bwriteln!\b/).size,
      tables: content.include?("comfy_table") || content.include?("tabled") || content.include?("prettytable"),
      progress: content.include?("indicatif") || content.include?("ProgressBar"),
      colors: content.include?("colored") || content.include?("termcolor") || content.include?("ansi_term")
    }
  end

  def find_inputs(content)
    {
      stdin: content.scan(/\bstdin\b/).size,
      args: content.scan(/\bstd::env::args\b/).size,
      clap: content.include?("clap::") || content.include?("use clap"),
      dialoguer: content.include?("dialoguer"),
      rustyline: content.include?("rustyline")
    }
  end

  def find_loops(content)
    {
      loop: content.scan(/\bloop\s*\{/).size,
      while: content.scan(/\bwhile\b/).size,
      for: content.scan(/\bfor\b/).size,
      iter: content.scan(/\.iter\(\)/).size
    }
  end

  def find_structs(content)
    content.scan(/^\s*(?:pub\s+)?struct\s+(\w+)/).flatten
  end

  def find_functions(content)
    content.scan(/^\s*(?:pub\s+)?(?:async\s+)?fn\s+(\w+)/).flatten
  end

  def report_outputs(outputs)
    puts
    bold "Outputs Detected"

    total = outputs[:println] + outputs[:print] + outputs[:eprintln] + outputs[:writeln]
    info "  Print macros: #{total}"
    info "  Tables: #{outputs[:tables] ? 'Yes' : 'No'}"
    info "  Progress bars: #{outputs[:progress] ? 'Yes' : 'No'}"
    info "  Colors: #{outputs[:colors] ? 'Yes' : 'No'}"
  end

  def report_inputs(inputs)
    puts
    bold "Inputs Detected"

    info "  stdin usage: #{inputs[:stdin]}"
    info "  std::env::args: #{inputs[:args] > 0 ? 'Yes' : 'No'}"
    info "  clap: #{inputs[:clap] ? 'Yes' : 'No'}"
    info "  dialoguer: #{inputs[:dialoguer] ? 'Yes' : 'No'}"
  end

  def report_structure(analysis)
    puts
    bold "Structure"

    info "  Structs: #{analysis[:structs].join(', ')}" if analysis[:structs].any?
    info "  Functions: #{analysis[:functions].size}"
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
      suggestions << ["Table", "Replace comfy_table/tabled with ratatui Table widget"]
    end

    if outputs[:progress]
      suggestions << ["Gauge/LineGauge", "Replace indicatif with Gauge widget"]
    end

    if outputs[:println] > 10
      suggestions << ["Paragraph", "Consolidate output into Paragraph widgets"]
    end

    # Based on inputs
    if inputs[:stdin] > 0 || inputs[:dialoguer]
      suggestions << ["TextInput", "Use /ratatui:snippet input for text entry"]
    end

    if inputs[:clap] || inputs[:args] > 0
      suggestions << ["CommandPalette", "Use /ratatui:component command_palette"]
    end

    # Based on structure
    if analysis[:loops][:loop] > 0
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

    basename = File.basename(path, ".rs")

    if analysis[:outputs][:tables]
      puts <<~TEXT
        This program uses tables. Consider a list-based TUI:

          /ratatui:scaffold #{basename}_tui list

        Then:
        1. Convert table data to list/table items
        2. Add Table widget for detailed view
        3. Add keyboard navigation (j/k/Enter)

      TEXT
    elsif analysis[:loops][:loop] > 0
      puts <<~TEXT
        This program has a main loop. Good candidate for TUI:

          /ratatui:scaffold #{basename}_tui dashboard

        Then:
        1. Move loop logic to event handler
        2. Convert prints to widget renders
        3. Add status bar for current state

      TEXT
    elsif analysis[:outputs][:progress]
      puts <<~TEXT
        This program has progress indicators. Use Gauge widget:

          /ratatui:scaffold #{basename}_tui basic

        Add Gauge for progress:
        ```rust
        let gauge = Gauge::default()
            .ratio(progress)
            .label(format!("{}%", (progress * 100.0) as u32))
            .gauge_style(Style::new().fg(Color::Green));
        frame.render_widget(gauge, area);
        ```

      TEXT
    else
      puts <<~TEXT
        Standard CLI program. Start with basic scaffold:

          /ratatui:scaffold #{basename}_tui basic

        Then:
        1. Identify main output → Paragraph widget
        2. Add Block containers for sections
        3. Add keyboard shortcuts for actions

      TEXT
    end

    puts "Cargo.toml dependencies:"
    puts "```toml"
    puts '[dependencies]'
    puts 'ratatui = "0.29"'
    puts 'crossterm = "0.28"'
    puts "```"
    puts
    puts "Run /ratatui:docs all to load full documentation."
  end
end

RatatuiConvert.run
