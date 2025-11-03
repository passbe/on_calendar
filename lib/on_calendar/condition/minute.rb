# frozen_string_literal: true

module OnCalendar
  module Condition
    class Minute < Base
      RANGE = (0..59)

      # NOTE: by default we validate number in default range but this needs to be context aware
      # because not all days have all minutes (ie: DST changes with 30 mins)
      # NOTE: With Condition::Hour we check dst_day? I haven't been able to work out how to check for DST change within an hour without jumping boundaries of DST. Therefore we check the entire day. This might have a small performance impact but we generally aren't looping over each hour when checking conditions.
      def range(clamp: nil)
        # If we are dealing with DST
        if clamp.present? and dst_day?(clamp: clamp)
          mins = []
          # NOTE: We can't use Time.beginning_of_hour because we may jump across DST boundary
          cursor = clamp.end_of_hour
          hour = clamp.hour
          zone = clamp.zone
          # Record each minute of the hour until we change hour || zone
          loop do
            mins << cursor.min
            cursor = cursor - 1.minute
            break if cursor.hour != hour or cursor.zone != zone
          end
          mins.reverse
        else
          RANGE
        end
      end
    end
  end
end
