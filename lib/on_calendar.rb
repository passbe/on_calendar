# frozen_string_literal: true

require "active_support/all"

module OnCalendar
  autoload :Version, "on_calendar/version"
  autoload :Parser, "on_calendar/parser"
  autoload :Condition, "on_calendar/condition"
  autoload :Segment, "on_calendar/segment"
end
