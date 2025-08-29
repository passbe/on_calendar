# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "on_calendar"

require "minitest/autorun"
require "minitest/spec"
require "minitest/stub_any_instance"
require "minitest/reporters"
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |rb| require(rb) }
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
