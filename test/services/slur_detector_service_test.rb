# frozen_string_literal: true

require "test_helper"

class SlurDetectorServiceTest < ActiveSupport::TestCase
  test "allows normal text" do
    detector = SlurDetectorService.new("Hello world")
    assert_not detector.contains_slur?
  end

  test "allows swear words" do
    detector = SlurDetectorService.new("damn shit fuck ass")
    assert_not detector.contains_slur?
  end

  test "allows drug references" do
    detector = SlurDetectorService.new("marijuana cocaine weed heroin meth")
    assert_not detector.contains_slur?
  end

  test "handles empty input" do
    assert_not SlurDetectorService.new("").contains_slur?
  end

  test "handles nil input" do
    assert_not SlurDetectorService.new(nil).contains_slur?
  end

  test "handles whitespace-only input" do
    assert_not SlurDetectorService.new("   \n\t  ").contains_slur?
  end

  test "normalizes leetspeak" do
    detector = SlurDetectorService.new("h3ll0 w0rld")
    normalized = detector.send(:normalize_text, "h3ll0 w0rld")
    assert_equal "hello world", normalized
  end

  test "handles mixed case" do
    detector = SlurDetectorService.new("HeLLo WoRLD")
    normalized = detector.send(:normalize_text, "HeLLo WoRLD")
    assert_equal "hello world", normalized
  end

  test "strips non-alphabetic characters after leetspeak conversion" do
    detector = SlurDetectorService.new("hello.world")
    normalized = detector.send(:normalize_text, "hello.world")
    # Periods are stripped, no leetspeak conversion needed
    assert_equal "helloworld", normalized
  end

  test "handles unicode normalization" do
    detector = SlurDetectorService.new("cafe")
    # NFKD normalization decomposes accented characters
    normalized = detector.send(:normalize_text, "cafe")
    assert_equal "cafe", normalized
  end

  test "skips very short words" do
    # Words under 3 characters should be skipped
    detector = SlurDetectorService.new("a b c")
    assert_not detector.contains_slur?
  end

  test "allows place names that might be false positives" do
    # Scunthorpe problem - should not match substrings
    detector = SlurDetectorService.new("I visited Scunthorpe")
    assert_not detector.contains_slur?
  end

  test "allows concatenated text without word boundaries" do
    # Should not match slurs embedded in other words
    detector = SlurDetectorService.new("wineglass")
    assert_not detector.contains_slur?
  end
end
