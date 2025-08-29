# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Condition::DayOfMonth do
  let(:dom) { OnCalendar::Condition::DayOfMonth.new(base: 1) }

  describe "range" do
    it "default" do
      assert_equal (1..31), dom.range
    end

    [1, 3, 5, 7, 8, 10, 12].each do |month|
      it "31 max range for month #{month}" do
        assert_equal (1..31), dom.range(year: 2000, month: month)
      end
    end

    [4, 6, 9, 11].each do |month|
      it "30 max range for month #{month}" do
        assert_equal (1..30), dom.range(year: 2000, month: month)
      end
    end

    it "month of 28 days" do
      assert_equal (1..28), dom.range(year: 2001, month: 2)
    end

    it "leap year" do
      assert_equal (1..29), dom.range(year: 2000, month: 2)
    end
  end
end
