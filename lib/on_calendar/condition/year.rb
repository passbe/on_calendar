# frozen_string_literal: true

module OnCalendar
  module Condition
    class Year < Base
      RANGE = (1970..2200)

      def initialize(base: nil, step: nil, wildcard: false)
        # Translate short year to long
        unless base.nil?
          if (0..69).cover?(base)
            base += 2000
          elsif (70..99).cover?(base)
            base += 1900
          end
        end
        super
      end
    end
  end
end
