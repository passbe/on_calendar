# frozen_string_literal: true

module OnCalendar
  module Segment
    class Error < StandardError; end

    module_function

    WILDCARD_CHAR = "*"
    LIST_CHAR = ","
    RANGE_CHAR = ".."
    STEP_CHAR = "/"
    CHARS_REGEX = /\A[a-zA-Z]+\z/
    NUMERIC_REGEX = /\A\d+\z/

    # Take complex segment expressions and break it down into an array of bases (integer||range) and steps (integer)
    def parse(expression, max: nil, min: nil)
      # Any Value
      return nil if expression == WILDCARD_CHAR || expression.nil? || expression.empty?

      # Check if we have a list and break into segments
      segments = []
      if expression.include?(LIST_CHAR)
        segments.concat(expression.split(LIST_CHAR))
      else
        segments << expression
      end

      # Lets parse each segment
      results = []
      segments.each do |segment|
        step, bases = nil

        # Parse step (if present)
        segment, step = parse_step(segment) if segment.include?(STEP_CHAR)

        # Parse range (if present)
        if segment.include?(RANGE_CHAR)
          bases = parse_range(segment, max: max, min: min)
        else
          # Default to 0 if wild card present
          segment = "0" if segment == WILDCARD_CHAR
          bases = [cast(segment)]
        end

        # We may end up with multiple bases so lets add each
        bases&.each do |b|
          results << { base: b, step: step }
        end
      end
      results
    end

    # First weekday name to integer conversion, otherwise numerical to integer
    def cast(expression)
      # If only characters lets try day_of_week
      if expression.match?(CHARS_REGEX)
        begin
          return Date.parse(expression).wday
        rescue Date::Error
          # We need to try parse weekday here - otherwise try for integer
        end
      end

      # Otherwise try numerical
      unless expression.match?(NUMERIC_REGEX)
        raise OnCalendar::Segment::Error, "Character not allowed in expression: #{expression}"
      end

      expression.to_i
    end

    # Parse string range to real range (also deal with desc ranges - only weekdays)
    def parse_range(expression, max: nil, min: nil)
      start_val, end_val = expression.split(RANGE_CHAR)
      raise OnCalendar::Segment::Error, "Invalid range detected #{expression}" if start_val.nil? || end_val.nil?

      results = [(cast(start_val)..cast(end_val))]
      # If we have a range like 6..0 we need to split these out
      if results.first.first > results.first.last
        # Only transform if we intended to
        raise OnCalendar::Segment::Error, "Invalid range: #{results.first}" unless !max.nil? && !min.nil?

        old_range = results.pop
        # Add from start of range to max || max
        results << (old_range.first == max ? max : (old_range.first..max))
        # Add from min to end of range || min
        results << (old_range.last == min ? min : (min..old_range.last))
      end
      results
    end

    # Parse a step out of a segment 1/5 = ["1", 5]
    def parse_step(expression)
      base, step = expression.split(STEP_CHAR)
      step = cast(step) unless step.nil?
      [base, step]
    end
  end
end
