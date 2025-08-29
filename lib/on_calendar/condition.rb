# frozen_string_literal: true

module OnCalendar
  module Condition
    class Error < StandardError; end

    autoload :Base, "on_calendar/condition/base"
    autoload :Hour, "on_calendar/condition/hour"
    autoload :Minute, "on_calendar/condition/minute"
    autoload :Second, "on_calendar/condition/second"
    autoload :Year, "on_calendar/condition/year"
    autoload :Month, "on_calendar/condition/month"
    autoload :DayOfMonth, "on_calendar/condition/day_of_month"
    autoload :DayOfWeek, "on_calendar/condition/day_of_week"
  end
end
