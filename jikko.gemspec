# frozen_string_literal: true

require_relative "lib/jikko/version"

Gem::Specification.new do |spec|
  spec.name = "jikko"
  spec.version = Jikko::VERSION
  spec.authors = ["chi"]
  spec.email = ["chi@saiden.pl"]

  spec.summary = "CLI scripts for Claude Code"
  spec.description = "CLI utilities for Claude Code slash commands"
  spec.homepage = "https://github.com/aladac/jikko"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.glob("{exe,lib}/**/*") + %w[README.md]
  spec.bindir = "exe"
  spec.executables = ["jikko"]
  spec.require_paths = ["lib"]

  spec.add_dependency "cli-ui", "~> 2.0"
end
