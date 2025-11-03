# frozen_string_literal: true

require_relative "lib/on_calendar/version"

Gem::Specification.new do |spec|
  spec.name = "on_calendar"
  spec.version = OnCalendar::VERSION
  spec.authors = ["Ben Passmore"]
  spec.email = ["contact@passbe.com"]

  spec.summary = "Parser for OnCalendar expressions used by systemd time."
  spec.homepage = "https://github.com/passbe/on_calendar"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/passbe/on_calendar/issues",
    "changelog_uri" => "https://github.com/passbe/on_calendar/releases",
    "source_code_uri" => "https://github.com/passbe/on_calendar",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.glob(%w[LICENSE.txt README.md lib/**/*]).reject { |f| File.directory?(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 8.0"
  spec.add_dependency "terminal-table", "~> 4.0.0"
end
