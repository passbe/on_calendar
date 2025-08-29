# frozen_string_literal: true

module OnCalendar
  module Condition
    class DayOfMonth < Base
      RANGE = (1..31)

      # NOTE: by default we validate number in default range but this needs to be context aware
      # because not all months have the same number of days
      def range(year: nil, month: nil)
        if year.nil? || month.nil?
          RANGE
        else
          (RANGE.min..Time.days_in_month(month, year))
        end
      end
    end
  end
end
