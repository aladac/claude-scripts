#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../ruby/generator"

class RatatuiDocs < Claude::Generator
  METADATA = { name: "ratatui:docs", desc: "Load RatatuiRuby documentation" }.freeze

  DOC_DIR = File.expand_path("../../../../doc/ratatui", __FILE__)

  TOPICS = {
    "quickstart" => "Getting started, lifecycle, viewport modes",
    "widgets" => "All widgets + Style reference",
    "layout" => "Constraints, Rect, nested layouts",
    "state" => "ListState, TableState, stateful rendering",
    "events" => "Key, mouse, resize, pattern matching",
    "testing" => "TestHelper, snapshots, debugging",
    "custom-widgets" => "Building custom widgets",
    "async" => "Background tasks, Process.spawn"
  }.freeze

  def execute
    topic = args.first&.downcase

    if topic.nil? || topic.empty?
      list_topics
    elsif topic == "all"
      show_all
    elsif TOPICS.key?(topic)
      show_topic(topic)
    else
      err "Unknown topic: #{topic}"
      puts
      list_topics
    end
  end

  private

  def list_topics
    section "RatatuiRuby Documentation"

    rows = TOPICS.map do |name, desc|
      path = File.join(DOC_DIR, "#{name}.md")
      exists = File.exist?(path) ? "✓" : "✗"
      [name, desc, exists]
    end

    table(%w[Topic Description File], rows)

    puts
    info "Usage: /ratatui:docs <topic>"
    info "       /ratatui:docs all"
  end

  def show_topic(topic)
    path = File.join(DOC_DIR, "#{topic}.md")

    if File.exist?(path)
      section "#{topic}.md"
      info home_path(path)
      puts
      # Output path for Claude to read
      puts "FILE_PATH=#{path}"
    else
      err "File not found: #{home_path(path)}"
    end
  end

  def show_all
    section "All Documentation"

    TOPICS.each_key do |topic|
      path = File.join(DOC_DIR, "#{topic}.md")
      if File.exist?(path)
        ok topic
        puts "FILE_PATH=#{path}"
      else
        err "Missing: #{topic}"
      end
    end
  end
end

RatatuiDocs.run
