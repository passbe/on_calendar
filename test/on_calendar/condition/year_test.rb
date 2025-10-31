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

    it "conversion 70..99 as range 1900s" do
      assert_equal 1970..1999, year.new(base: 70..99).base
      assert_equal 1988..1988, year.new(base: 88..88).base
    end

    it "conversion 0..69 2000s" do
      assert_equal 2000, year.new(base: 0).base
      assert_equal 2012, year.new(base: 12).base
      assert_equal 2069, year.new(base: 69).base
    end

    it "conversion 0..69 as range 2000s" do
      assert_equal 2000..2069, year.new(base: 0..69).base
      assert_equal 2001..2001, year.new(base: 1..1).base
    end

    it "conversion 1900s to 2000s range" do
      assert_equal 1971..2068, year.new(base: 71..68).base
    end

    it "mixed short year long year range" do
      assert_equal 1971..1988, year.new(base: 71..1988).base
      assert_equal 2000..2200, year.new(base: 0..2200).base
    end

    it "ensures min..max range" do
      assert_equal 2000..2015, year.new(base: 2015..2000).base
      assert_equal 2000..2015, year.new(base: 15..0).base
      assert_equal 1971..1975, year.new(base: 1975..1971).base
      assert_equal 1971..1975, year.new(base: 75..71).base
    end

    it "no conversion" do
      assert_equal 2000, year.new(base: 2000).base
      assert_equal 1970, year.new(base: 1970).base
      assert_equal 2100, year.new(base: 2100).base
      assert_equal 2000..2015, year.new(base: 2000..2015).base
      assert_equal 1970..2200, year.new(base: 1970..2200).base
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
