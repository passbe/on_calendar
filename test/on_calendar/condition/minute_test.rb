# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Condition::Minute do
  let(:min) { OnCalendar::Condition::Minute.new(base: 1) }

  describe "range" do
    it "default" do
      assert_equal (0..59), min.range
    end

    it "no DST" do
      clamp = Time.parse("2022-06-01 00:00:00 +1030").in_time_zone("Australia/Lord_Howe")
      refute clamp.dst?
      assert_equal (0..59), min.range(clamp: clamp)
    end

    it "jump forward DST" do
      clamp = Time.parse("2022-10-02 02:45:00 +1100").in_time_zone("Australia/Lord_Howe")
      assert clamp.dst?
      # We skip 0..29 because it doesn't exist
      assert_equal (30..59).to_a, min.range(clamp: clamp)
    end

    it "jump backward DST" do
      clamp = Time.parse("2022-04-03 01:45:00 +1030").in_time_zone("Australia/Lord_Howe")
      refute clamp.dst?
      # We skip 0..29 because it doesn't exist
      assert_equal (30..59).to_a, min.range(clamp: clamp)
    end

    it "full range on hour after backward DST" do
      clamp = Time.parse("2022-04-03 02:00:00 +1030").in_time_zone("Australia/Lord_Howe")
      refute clamp.dst?
      assert_equal (0..59).to_a, min.range(clamp: clamp)
    end
  end
end
