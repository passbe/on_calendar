# frozen_string_literal: true

module OnCalendar
  class Parser
    class Error < StandardError; end

    MAX_ITERATIONS = 4000
    TIME_SEP_CHAR = ":"
    DATE_SEP_CHAR = "-"
    DATETIME_SEP_CHAR = "T"
    DATETIME_SEP_REGEX = /\d|\*#{DATETIME_SEP_CHAR}\d|\*/
    SPECIAL_EXPRESSIONS = {
      minutely: "*-*-* *:*:00",
      hourly: "*-*-* *:00:00",
      daily: "*-*-* 00:00:00",
      monthly: "*-*-01 00:00:00",
      weekly: "Mon *-*-* 00:00:00",
      yearly: "*-01-01 00:00:00",
      quarterly: "*-01,04,07,10-01 00:00:00",
      semiannually: "*-01,07-01 00:00:00"
    }.freeze

    attr_reader :expression, :timezone, :years, :months, :days_of_month,
                :days_of_week, :hours, :minutes, :seconds

    def initialize(expression)
      parse(expression)
      @expression = expression
    end

    def next(count=1, clamp: timezone.now, debug: false)
      raise OnCalendar::Parser::Error, "Clamp must be instance of Time" unless clamp.is_a?(Time)

      # Translate to correct timezone and add 1.second to ensure
      # we get the "next" occurence and not the current Time.now
      clamp = clamp.in_time_zone(timezone) + 1.second

      results = []
      count.times do
        result = iterate(clamp: clamp, debug: debug)
        break if result.nil?

        clamp = result + 1.second
        results << result
      end
      results.empty? ? nil : results
    end

    def matches_any_conditions?(field:, base:)
      send(field).each do |condition|
        return true if condition.match?(base)
      end
      false
    end

    private

    def iterate(clamp:, debug: false)
      iterations = 0
      output = [["-", clamp.to_s, "", ""]] if debug

      while true
        # Fail safe
        if iterations >= MAX_ITERATIONS
          raise OnCalendar::Parser::Error, "Too many iterations: #{MAX_ITERATIONS}. Something has gone wrong."
        end

        iterations += 1

        # Loop over segments:
        # a) If we don't match any condition for that segment
        # b) Find all the next distances for a possible match
        #    if only nil distances return nil - not possible to compute
        # c) Advance clamp by the minimum distance found while resetting child segments
        field_manipulation = false
        {
          years: {
            base_method: :year,
            changes: { month: 1, day: 1, hour: 0, min: 0, sec: 0 }
          },
          months: {
            base_method: :month,
            changes: { day: 1, hour: 0, min: 0, sec: 0 }
          },
          days_of_month: {
            base_method: :day,
            changes: { hour: 0, min: 0, sec: 0 },
            increment_method: :days
          },
          days_of_week: {
            base_method: :wday,
            changes: { hour: 0, min: 0, sec: 0 },
            increment_method: :days
          },
          hours: {
            base_method: :hour,
            changes: { min: 0, sec: 0 }
          },
          minutes: {
            base_method: :min,
            changes: { sec: 0 }
          },
          seconds: {
            base_method: :sec
          }
        }.each do |field, values|
          # Do we miss all condition matches - thus increment
          next if matches_any_conditions?(field: field, base: clamp.send(values[:base_method]))

          # Determine distances required to jump to next match
          distances = send(field).map do |condition|
            condition.distance_to_next(clamp.send(values[:base_method]), range_args: clamp)
          end.sort!
          # Check for only nil - if so impossible to compute bail
          if distances.compact.empty?
            if debug
              output << [iterations, clamp.to_s, "impossible", ""]
              debug_table(output)
            end
            return nil
          end

          # Increment by field method
          method = values[:increment_method] || field
          clamp = (clamp + distances.min.send(method))
          # Reset desired fields
          clamp = clamp.change(**values[:changes]) if values.key?(:changes)
          # Force re-check everything by marking manipulation
          field_manipulation = true
          # Debug
          output << [
            iterations,
            clamp.to_s,
            field.to_s,
            distances.min
          ] if debug
          break
        end

        # If we have manipulated a field - we need to re-check, re-loop
        # otherwise we break out because we have a result
        field_manipulation ? next : break
      end

      # Output debug table
      debug_table(output) if debug

      clamp
    end

    def debug_table(rows)
      table = Terminal::Table.new do |t|
        t.headings = ["Iteration", "Datetime", "Function", "Distance"]
        t.rows = rows
      end
      puts table
    end

    def parse(expression)
      raise OnCalendar::Parser::Error, "Expression must be a string" unless expression.is_a?(String)
      raise OnCalendar::Parser::Error, "Expression cannot be empty" if expression.empty?

      # Split string on white space and reverse
      segments = expression.split.reverse

      # Detect if we have time zone
      @timezone = parse_timezone(segments.first)
      # Default timezone if no result - otherwise remove first segment
      if @timezone.nil?
        @timezone = ActiveSupport::TimeZone[Time.now.gmt_offset].tzinfo
      else
        segments.shift
      end

      # Detect if expression is special and override segments
      if segments.length == 1
        special = segments.first.downcase
        SPECIAL_EXPRESSIONS.each do |k, v|
          segments = v.split.reverse if special == k.to_s
        end
      end

      # Split on 'T' separator if it exists
      segments.prepend(*segments.shift.split(DATETIME_SEP_CHAR).reverse) if
        segments.first.match?(DATETIME_SEP_REGEX)

      # Check and parse time (default 00:00:00 otherwise)
      time_expression = segments.first.include?(TIME_SEP_CHAR) ? segments.shift : "00:00:00"
      @hours, @minutes, @seconds = parse_time(time_expression)

      # Check we have more segments, with date separator and start with number or wildcard
      if !segments.empty? && segments.first.include?(DATE_SEP_CHAR) && segments.first =~ /\A\d|\*/
        @years, @months, @days_of_month = parse_date(segments.shift)
      else
        @years, @months, @days_of_month = parse_date("*-*-*")
      end

      # Parse days of week
      @days_of_week = parse_day_of_week(segments.empty? ? "*" : segments.shift)

      # If we have remaining parts something went wrong
      raise OnCalendar::Parser::Error, "Expression parts not parsed: #{segments}" unless segments.empty?
    end

    def parse_time(expression)
      # Split and check we have enough parts
      segments = expression.split(TIME_SEP_CHAR)
      raise Error, "Time component is malformed" unless
        (2..3).cover?(segments.length)

      # If seconds do not exist default to 00
      segments << "00" if segments.length == 2

      # Build conditions
      build_conditions(
        items: %i[Hour Minute Second],
        segments: segments
      )
    end

    def parse_date(expression)
      # Split and check we have enough parts
      segments = expression.split(DATE_SEP_CHAR)
      raise Error, "Date component is malformed" unless
        (2..3).cover?(segments.length)

      # If year do not exist default to *
      segments.unshift "*" if segments.length == 2

      # Build conditions
      build_conditions(
        items: %i[Year Month DayOfMonth],
        segments: segments
      )
    end

    def parse_day_of_week(expression)
      conditions = build_conditions(
        items: [:DayOfWeek],
        segments: [expression]
      )
      # NOTE: We cheat here and flatten array due to single field
      conditions.first if conditions.is_a?(Array)
    end

    def parse_timezone(expression)
      TZInfo::Timezone.get(expression)
    rescue TZInfo::InvalidTimezoneIdentifier
      nil
    end

    def build_conditions(items:, segments:)
      conditions = []
      items.each_with_index do |klass, idx|
        # Help work with special ranges 6..0
        min, max = OnCalendar::Condition.const_get(klass).try(:range_bounds) || nil
        # Parse this segment
        begin
          parsed = OnCalendar::Segment.parse(segments.shift, max: max, min: min)
          if parsed.nil?
            # We are a wildcard
            conditions[idx] = [OnCalendar::Condition.const_get(klass).new(wildcard: true)]
          else
            # Lets build conditions with parsed
            conditions[idx] = []
            parsed.each do |c|
              conditions[idx] << OnCalendar::Condition.const_get(klass).new(**c)
            end
          end
        rescue OnCalendar::Segment::Error, OnCalendar::Condition::Error => e
          raise Error, e
        end
      end
      conditions
    end
  end
end
