# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Parser do
  let(:parser) { OnCalendar::Parser }

  describe "new" do
    it "valid timezone" do
      assert_instance_of TZInfo::DataTimezone, parser.new("Mon Australia/Brisbane").timezone
    end

    it "invalid timezone" do
      assert_raises parser::Error do
        parser.new("Mon Australia/brisbane")
      end
    end

    it "default timezone" do
      assert_instance_of TZInfo::DataTimezone, parser.new("Mon").timezone
      assert_equal ActiveSupport::TimeZone[Time.now.gmt_offset].tzinfo, parser.new("Mon").timezone
    end

    it "correctly splits 'T' date time seperator" do
      p = parser.new("Mon,Tue,Thur *-*-*T01:01:01")
      %i[years months days_of_month].each do |field|
        assert p.send(field).first.wildcard
      end
      %i[hours minutes seconds].each do |field|
        assert_equal 1, p.send(field).first.base
      end
      refute_empty p.days_of_week
    end

    it "default 00:00:00 without time" do
      p = parser.new("2000-01-01")
      %i[hours minutes seconds].each do |field|
        assert_instance_of Array, p.send(field)
        assert_equal 1, p.send(field).length
        assert_equal 0, p.send(field).first.base
      end
    end

    it "default 00 without seconds" do
      p = parser.new("2000-01-01 13:43")
      assert_instance_of Array, p.seconds
      assert_equal 1, p.seconds.length
      assert_equal 0, p.seconds.first.base
    end

    it "default *-*-* without date" do
      p = parser.new("13:43")
      %i[years months days_of_week days_of_month].each do |field|
        assert p.send(field).first.wildcard
      end
    end

    it "default * without year" do
      p = parser.new("01-01 13:43")
      assert p.years.first.wildcard
    end

    it "invalid expression - too many parts" do
      assert_raises parser::Error do
        parser.new("Mon, Sun 2,1:23 Europe/London")
      end
    end

    it "invalid expression" do
      assert_raises parser::Error do
        parser.new("M")
      end
    end

    it "nil expression" do
      assert_raises parser::Error do
        parser.new(nil)
      end
    end

    it "integer expression" do
      assert_raises parser::Error do
        parser.new(1)
      end
    end
    
    it "boolean expression" do
      assert_raises parser::Error do
        parser.new(false)
      end
    end

    it "array expression" do
      assert_raises parser::Error do
        parser.new([])
      end
    end
  end

  describe "next" do
    it "raises error if clamp not time" do
      assert_raises parser::Error do
        parser.new("Mon").next(clamp: Date.today)
      end
    end

    it "nil with impossible datetime" do
      # 2012-10-15 == Monday
      assert_nil parser.new("Wed..Sat,Tue 12-10-15 1:2:3").next
    end

    it "nil with no future datetime" do
      assert_nil parser.new("2000-01-01").next
    end

    it "converts clamp timezone" do
      # America/Barbados = -0400
      p = parser.new("2025-*-27 00:00:00 America/Barbados")
      result = p.next(clamp: Time.parse("2025-01-27 05:00:01 +0100")).first
      assert_equal 2, result.month
      assert_equal result.gmt_offset, p.timezone.now.timezone_offset.base_utc_offset
    end

    # Load * examples from fixtures and stress test
    YAML.load_file("test/fixtures/expressions.yaml", permitted_classes: [Time])["expressions"].each do |e|
      it "expression: #{e['expression']}" do
        results = parser.new(e["expression"])
          .next(e["iterations"].length, clamp: e["clamp"])
        refute_nil results
        # Compare results with iterations in fixtures
        results.each_with_index do |iteration, index|
          assert_equal e["iterations"][index].to_s, iteration.strftime("%Y-%m-%d %H:%M:%S %z")
        end
        # Ensure we generated the correct amount
        assert_equal e["iterations"].length, results.length
      end
    end
  end
end
