# frozen_string_literal: true

module OnCalendar
  module Condition
    class Hour < Base
      RANGE = (0..23)

      # NOTE: by default we validate number in default range but this needs to be context aware
      # because not all days have all hours (ie: DST changes)
      def range(clamp: nil)
        # If we are dealing with DST
        if clamp.present? and dst_day?(clamp: clamp)
          hours = []
          cursor = clamp.beginning_of_day
          day = clamp.day
          zone = clamp.zone
          # Record each hour of the day until we change day || zone
          loop do
            hours << cursor.hour
            cursor = cursor + 1.hour
            break if cursor.day != day or clamp.zone != zone
          end
          hours
        else
          RANGE
        end
      end
    end
  end
end
