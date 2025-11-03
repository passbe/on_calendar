# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Condition::Hour do
  let(:hour) { OnCalendar::Condition::Hour.new(base: 1) }

  describe "range" do
    it "default" do
      assert_equal (0..23), hour.range
    end

    it "no DST" do
      clamp = Time.parse("2025-06-01 00:00:00 +1000").in_time_zone("Australia/Sydney")
      refute clamp.dst?
      assert_equal (0..23), hour.range(clamp: clamp)
    end

    it "jump forward DST" do
      clamp = Time.parse("2025-10-05 00:00:00 +1000").in_time_zone("Australia/Sydney")
      refute clamp.dst?
      # We skip hour 3 because it doesn't exist
      assert_equal (0..23).to_a.reject{ |num|
          num == 2
      }, hour.range(clamp: clamp)
    end

    it "jump backward DST" do
      clamp = Time.parse("2025-04-06 00:00:00 +1100").in_time_zone("Australia/Sydney")
      assert clamp.dst?
      # We duplicate hour 2
      assert_equal (0..23).to_a.insert(3, 2), hour.range(clamp: clamp)
    end
  end
end
