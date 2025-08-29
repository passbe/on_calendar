# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Condition::Year do
  let(:year) { OnCalendar::Condition::Year }

  describe "new" do
    it "conversion 70..99 1900s" do
      assert_equal 1970, year.new(base: 70).base
      assert_equal 1982, year.new(base: 82).base
      assert_equal 1999, year.new(base: 99).base
    end

    it "conversion 0..69 2000s" do
      assert_equal 2000, year.new(base: 0).base
      assert_equal 2012, year.new(base: 12).base
      assert_equal 2069, year.new(base: 69).base
    end

    it "no conversion" do
      assert_equal 2000, year.new(base: 2000).base
      assert_equal 1970, year.new(base: 1970).base
      assert_equal 2100, year.new(base: 2100).base
    end

    it "raises error < RANGE.min" do
      assert_raises OnCalendar::Condition::Error do
        year.new(base: year::RANGE.min - 1)
      end
    end

    it "raises error > RANGE.max" do
      assert_raises OnCalendar::Condition::Error do
        year.new(base: year::RANGE.max + 1)
      end
    end
  end
end
