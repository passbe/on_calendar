# frozen_string_literal: true

module OnCalendar
  module Condition
    class DayOfWeek < Base
      RANGE = (0..6)

      # Utility function to pass our min,max range to the segment parser
      # this helps dealing with when the parser comes back with 6..0
      def self.range_bounds
        RANGE.minmax
      end
    end
  end
end
