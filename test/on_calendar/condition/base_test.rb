# frozen_string_literal: true

require "test_helper"

describe OnCalendar::Condition::Base do
  let(:base) { OnCalendar::Condition::Base }

  describe "new" do
    it "raises error with nil arguments" do
      assert_raises OnCalendar::Condition::Error do
        base.new
      end
    end

    it "raises error only step argument" do
      assert_raises OnCalendar::Condition::Error do
        base.new(step: 5)
      end
    end

    it "raises error when invalid integer" do
      assert_raises OnCalendar::Condition::Error do
        base.stub_any_instance(:range, 1..10) do
          base.new(base: 11)
        end
      end
    end

    it "raises error when invalid range" do
      assert_raises OnCalendar::Condition::Error do
        base.stub_any_instance(:range, 1..10) do
          base.new(base: 1..11)
        end
      end
    end

    it "raises error when step 0" do
      assert_raises OnCalendar::Condition::Error do
        base.stub_any_instance(:range, 1..10) do
          base.new(base: 2, step: 0)
        end
      end
    end

    it "raises error when step > RANGE.max" do
      assert_raises OnCalendar::Condition::Error do
        base.stub_any_instance(:range, 1..10) do
          base.new(base: 2, step: 11)
        end
      end
    end
  end

  describe "range" do
    it "returns RANGE" do
      range = (1..10)
      base.stub_any_instance(:range, range) do
        assert_equal range, base.new(wildcard: true).range
      end
    end
  end

  describe "match?" do
    it "wildcard" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(wildcard: true).match?(9999)
      end
    end

    it "integer" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(base: 5).match?(5)
      end
    end

    it "integer false" do
      base.stub_any_instance(:range, 1..10) do
        refute base.new(base: 5).match?(6)
      end
    end

    it "range middle" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(base: 1..10).match?(5)
      end
    end

    it "range min" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(base: 1..10).match?(1)
      end
    end

    it "range max" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(base: 1..10).match?(10)
      end
    end

    it "range false" do
      base.stub_any_instance(:range, 1..10) do
        refute base.new(base: 4..8).match?(1)
      end
    end

    describe "with step" do
      it "integer" do
        base.stub_any_instance(:range, 1..10) do
          assert base.new(base: 2, step: 3).match?(8)
        end
      end

      it "integer false" do
        base.stub_any_instance(:range, 1..10) do
          refute base.new(base: 2, step: 3).match?(3)
        end
      end

      it "range" do
        base.stub_any_instance(:range, 1..10) do
          assert base.new(base: 2..8, step: 2).match?(6)
        end
      end

      it "range false" do
        base.stub_any_instance(:range, 1..10) do
          refute base.new(base: 2..8, step: 2).match?(7)
        end
      end
    end
  end

  describe "valid?" do
    it "true for base integer" do
      base.stub_any_instance(:range, 1..10) do
        assert_predicate base.new(base: 5), :valid?
      end
    end

    it "true for value integer" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(base: 5).valid?(value: 9)
      end
    end

    it "false for value integer" do
      base.stub_any_instance(:range, 1..10) do
        refute base.new(base: 5).valid?(value: 11)
      end
    end

    it "true for base range" do
      base.stub_any_instance(:range, 1..10) do
        assert_predicate base.new(base: 1..10), :valid?
      end
    end

    it "true for value range" do
      base.stub_any_instance(:range, 1..10) do
        assert base.new(base: 1..10).valid?(value: 2..8)
      end
    end

    it "false for value range" do
      base.stub_any_instance(:range, 1..10) do
        refute base.new(base: 2..8).valid?(value: 20..1)
      end
    end

    it "true for wildcard" do
      base.stub_any_instance(:range, 1..10) do
        assert_predicate base.new(wildcard: true), :valid?
      end
    end
  end

  describe "distance_to_next" do
    it "nil if invalid" do
      base.stub_any_instance(:range, 1..10) do
        assert_nil base.new(base: 5).distance_to_next(9999)
        assert_nil base.new(base: 5).distance_to_next(0)
      end
    end

    it "1 if wildcard" do
      base.stub_any_instance(:range, 1..10) do
        assert_equal 1, base.new(wildcard: true).distance_to_next(5)
      end
    end

    it "distance if integer" do
      base.stub_any_instance(:range, 1..10) do
        b = base.new(base: 5)
        assert_equal 3, b.distance_to_next(2)
        assert_equal 4, b.distance_to_next(1)
        assert_equal 1, b.distance_to_next(4)
        assert_equal 5, b.distance_to_next(6)
        assert_equal 6, b.distance_to_next(5)
      end
    end

    it "distance if range" do
      base.stub_any_instance(:range, 1..10) do
        b = base.new(base: 3..8)
        assert_equal 1, b.distance_to_next(4)
        assert_equal 1, b.distance_to_next(7)
        assert_equal 3, b.distance_to_next(8)
        assert_equal 1, b.distance_to_next(6)
        assert_equal 1, b.distance_to_next(3)
        assert_equal 2, b.distance_to_next(1)
      end
    end

    describe "with step" do
      it "distance if integer" do
        base.stub_any_instance(:range, 1..20) do
          b = base.new(base: 1, step: 4)
          assert_equal 3, b.distance_to_next(2)
          assert_equal 4, b.distance_to_next(5)
          assert_equal 3, b.distance_to_next(10)
          assert_equal 2, b.distance_to_next(19)
        end
      end

      it "distance if range" do
        base.stub_any_instance(:range, 1..20) do
          b = base.new(base: 5..15, step: 4)
          assert_equal 4, b.distance_to_next(5)
          assert_equal 3, b.distance_to_next(6)
          assert_equal 1, b.distance_to_next(8)
          assert_equal 8, b.distance_to_next(13)
          assert_equal 2, b.distance_to_next(19)
        end
      end
    end
  end
end
