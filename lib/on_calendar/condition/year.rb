# frozen_string_literal: true

module OnCalendar
  module Condition
    class Year < Base
      RANGE = (1970..2200)

      def initialize(base: nil, step: nil, wildcard: false)
        # Translate short year to long
        unless base.nil?
          if base.is_a?(Range)
            values = [
              translate_short_year(base.begin),
              translate_short_year(base.end)
            ]
            base = (values.min..values.max)
          else
            base = translate_short_year(base)
          end
        end
        super
      end

      private

      def translate_short_year(base)
        if (0..69).cover?(base)
          base += 2000
        elsif (70..99).cover?(base)
          base += 1900
        else
          base
        end
      end
    end
  end
end
