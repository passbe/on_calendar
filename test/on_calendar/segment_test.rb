# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Segment do
  let(:segment) { OnCalendar::Segment }

  describe "parse" do
    it "nil with no expression" do
      assert_nil segment.parse(nil)
    end

    it "nil with empty expression" do
      assert_nil segment.parse("")
    end

    it "nil with wildcard character" do
      assert_nil segment.parse(segment::WILDCARD_CHAR)
    end

    it "valid with expression: 5" do
      assert_equal [{ base: 5, step: nil }], segment.parse("5")
    end

    it "valid with expression: 05" do
      assert_equal [{ base: 5, step: nil }], segment.parse("05")
    end

    it "valid with expression: 9999" do
      assert_equal [{ base: 9999, step: nil }], segment.parse("9999")
    end

    it "valid with expression: 00" do
      assert_equal [{ base: 0, step: nil }], segment.parse("00")
    end

    it "valid with expression: */15" do
      assert_equal [{ base: 0, step: 15 }], segment.parse("*/15")
    end

    it "valid with expression: 0/5" do
      assert_equal [{ base: 0, step: 5 }], segment.parse("0/5")
    end

    it "valid with expression: 874/564" do
      assert_equal [{ base: 874, step: 564 }], segment.parse("874/564")
    end

    it "valid with expression: 1..10" do
      assert_equal [{ base: (1..10), step: nil }], segment.parse("1..10")
    end

    it "valid with expression: 9..10" do
      assert_equal [{ base: (9..10), step: nil }], segment.parse("9..10")
    end

    it "valid with expression: 1..1" do
      assert_equal [{ base: (1..1), step: nil }], segment.parse("1..1")
    end

    it "valid with expression: 1..8585/555" do
      assert_equal [{ base: (1..8585), step: 555 }], segment.parse("1..8585/555")
    end

    describe "weekdays" do
      it "valid with expression: Sun" do
        assert_equal [{ base: 0, step: nil }], segment.parse("Sun")
      end

      it "valid with expression: Sun/2,Wed/5" do
        assert_equal [
          { base: 0, step: 2 },
          { base: 3, step: 5 }
        ], segment.parse("Sun/2,Wed/5")
      end

      it "valid with expression: Sat..Sun" do
        assert_equal [
          { base: 6, step: nil },
          { base: 0, step: nil }
        ], segment.parse("Sat..Sun", min: 0, max: 6)
      end

      it "valid with expression: Wed..Sun" do
        assert_equal [
          { base: 3..6, step: nil },
          { base: 0, step: nil }
        ], segment.parse("Wed..Sun", min: 0, max: 6)
      end

      it "valid with expression: Wed..Mon" do
        assert_equal [
          { base: 3..6, step: nil },
          { base: 0..1, step: nil }
        ], segment.parse("Wed..Mon", min: 0, max: 6)
      end

      it "valid with expression: Sat..Wed" do
        assert_equal [
          { base: 6, step: nil },
          { base: 0..3, step: nil }
        ], segment.parse("Sat..Wed", min: 0, max: 6)
      end
    end

    it "valid with expression: 1,2,3" do
      assert_equal [
        { base: 1, step: nil },
        { base: 2, step: nil },
        { base: 3, step: nil }
      ], segment.parse("1,2,3")
    end

    it "valid with expression: 1..20,0..1/2" do
      assert_equal [
        { base: (1..20), step: nil },
        { base: (0..1), step: 2 }
      ], segment.parse("1..20,0..1/2")
    end

    it "valid with expression: */5,59/89" do
      assert_equal [
        { base: 0, step: 5 },
        { base: 59, step: 89 }
      ], segment.parse("*/5,59/89")
    end

    it "valid with expression: 99,99..101,99/1,*/99,1..88/2" do
      assert_equal [
        { base: 99, step: nil },
        { base: (99..101), step: nil },
        { base: 99, step: 1 },
        { base: 0, step: 99 },
        { base: (1..88), step: 2 }
      ], segment.parse("99,99..101,99/1,*/99,1..88/2")
    end

    it "raises error with whitespace in list" do
      assert_raises segment::Error do
        segment.parse("1, 2")
      end
    end

    [
      "-1",
      "a",
      "Mon@@",
      "99.9",
      " 1",
      "1  ",
      "-1..-10",
      "..10",
      "1..",
      "1..99.9",
      "1 .. 1",
      "1.1",
      "1.. 2",
      "1..*",
      "M..F",
      "-1/5",
      " /1",
      "9/99.0",
      "*/*"
    ].each do |value|
      it "raises error with disallowed character: #{value}" do
        assert_raises segment::Error do
          segment.parse(value)
        end
      end
    end
  end

  describe "cast" do
    it "base integer with numeric string" do
      assert_equal 44, segment.cast("44")
    end

    it "raises error with negative number" do
      assert_raises segment::Error do
        segment.cast("-1")
      end
    end

    ["@", " ", "M", "!", "#", "+", "Mon Fri"].each do |character|
      it "raises error with non-numeric character: #{character}" do
        assert_raises segment::Error do
          segment.cast(character)
        end
      end
    end

    Date::DAYNAMES.each_with_index do |day, i|
      it "#{i} for titleized weekday: #{day}" do
        assert_equal i, segment.cast(day)
      end

      it "#{i} for lower case weekday: #{day.downcase}" do
        assert_equal i, segment.cast(day.downcase)
      end

      it "#{i} for upper case weekday: #{day.upcase}" do
        assert_equal i, segment.cast(day.upcase)
      end

      it "#{i} for short weekday: #{day[0..2]}" do
        assert_equal i, segment.cast(day[0..2])
      end

      it "#{i} for short lower case weekday: #{day[0..2].downcase}" do
        assert_equal i, segment.cast(day[0..2].downcase)
      end

      it "#{i} for short upper case weekday: #{day[0..2].upcase}" do
        assert_equal i, segment.cast(day[0..2].upcase)
      end
    end
  end

  describe "parse_range" do
    it "valid range" do
      assert_equal [(0..20)], segment.parse_range("0..20")
    end

    describe "descending range" do
      it "raises error without min/max" do
        assert_raises segment::Error do
          segment.parse_range("20..1")
        end
      end

      it "return ranges" do
        assert_equal [(15..20), (1..5)], segment.parse_range("15..5", max: 20, min: 1)
      end

      it "return min + range" do
        assert_equal [(15..20), 1], segment.parse_range("15..1", max: 20, min: 1)
      end

      it "return max + range" do
        assert_equal [20, (1..10)], segment.parse_range("20..10", max: 20, min: 1)
      end

      it "returns min + max" do
        assert_equal [20, 1], segment.parse_range("20..1", max: 20, min: 1)
      end
    end
  end

  describe "parse_step" do
    it "returns segment string and step" do
      assert_equal ["5", 44], segment.parse_step("5/44")
    end

    it "returns segment string (range) and step" do
      assert_equal ["1..8", 44], segment.parse_step("1..8/44")
    end

    it "raises error with negative" do
      assert_raises segment::Error do
        segment.parse_step("5/-44")
      end
    end

    it "nil with no step" do
      assert_equal ["5", nil], segment.parse_step("5")
    end
  end
end
