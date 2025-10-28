# frozen_string_literal: true

module OnCalendar
  module Condition
    class Base
      attr_reader :base, :step, :wildcard

      def initialize(base: nil, step: nil, wildcard: false)
        @base = base
        @step = step
        @wildcard = wildcard

        raise OnCalendar::Condition::Error, "Must supply base or wildcard=true" if
          base.nil? && !wildcard
        raise OnCalendar::Condition::Error, "Condition base value #{base} outside of allowed range #{range}" unless
          valid?
        raise OnCalendar::Condition::Error, "Condition step value #{step} must be > 0 and < than #{range.max}" if
          !step.nil? && (step == 0 || step > range.max)
      end

      # Some subclasses need more context for RANGE
      def range
        self.class::RANGE
      end

      # Match this condition
      # - If wild card return true
      # No step:
      #   - If within range true
      #   - Otherwise if base == argument
      # With step:
      #   - Expand possible options to range.max
      #     does our argument match
      def match?(part)
        return true if wildcard

        if step.nil?
          return base.cover?(part) if base.is_a?(Range)

          base == part
        else
          (base.is_a?(Range) ? base : (base..range.max)).step(step).to_a.include?(part)
        end
      end

      # Validates whether value (if passed otherwise base) is acceptable
      # Note: This is not context aware so you can pass it day 31 for a 30 day month and it will return true
      def valid?(value: nil)
        # Always yes for wildcard when value isn't supplied
        return true if wildcard && value.nil?

        value ||= base
        case value
        when Range
          # Check range is within RANGE
          return true if range.cover?(value)
        else
          # Check value is within RANGE
          return true if range.include?(value)
        end
        false
      end

      # Get next distance to valid base, if we rotate through range we get distance to min
      # Note: We need to pass range_args becaue some subclasses need the context (ie: day_of_month)
      def distance_to_next(current, range_args: nil)
        # If we have an invalid value no point continuing
        return nil unless valid?(value: current)
        # Wild card return +1
        return 1 if wildcard

        # Build array to find needle_index
        arr = range_args.nil? ? range.to_a : range(**range_args).to_a
        needle_index = arr.index(current)

        return nil if needle_index.nil?

        # Default to increment value by 1
        distance = 1

        if step.nil?
          # If we are dealing with a range and the current and current+1 within range
          if base.is_a?(Range)
            if base.cover?(current) &&
               base.cover?(arr.fetch(needle_index + 1, nil))
              # Set +1 index
              target_index = needle_index + 1
            else
              # Otherwise set the index of the minimum acceptable value
              target_index = arr.index(base.min)
            end
          else
            # Set index of base value
            target_index = arr.index(base)
          end
        # We have a step, we have to compare stepped array to get next distance otherwise min
        else
          # If base is range - we find the next value in base
          if base.is_a?(Range)
            stepped_arr = base.step(step).to_a
            next_value = stepped_arr.bsearch { |x| x > current } || base.min
          # Else we find next value in full RANGE
          else
            stepped_arr = (base..arr.max).step(step).to_a
            next_value = stepped_arr.bsearch { |x| x > current } || arr.min
          end
          target_index = arr.index(next_value)
        end

        # Lets work out distance between target_index and needle_index
        if !target_index.nil? && needle_index < target_index
          # If the needle is before target get how many steps we need to step
          distance = target_index - needle_index
        else
          # If is in front of us loop over until start of array
          # Note: This sounds counter intuitive - why not give the distance until the next value
          #       However this forces us to re-evaluate all other date parts otherwise we might jump forward too far
          distance = arr.length - needle_index
        end
        distance
      end
    end
  end
end
