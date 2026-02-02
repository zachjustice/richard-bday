# frozen_string_literal: true

require "digest"

class SlurDetectorService
  # Leetspeak normalization map
  LEETSPEAK_MAP = {
    "@" => "a", "4" => "a", "^" => "a",
    "8" => "b",
    "(" => "c", "<" => "c",
    "3" => "e",
    "6" => "g", "9" => "g",
    "#" => "h",
    "1" => "i", "!" => "i", "|" => "i",
    "0" => "o",
    "$" => "s", "5" => "s",
    "7" => "t", "+" => "t"
  }.freeze

  MINIMUM_WORD_LENGTH = 3

  def initialize(text)
    @text = text.to_s
  end

  def contains_slur?
    return false if @text.blank?

    words = extract_words(@text)
    words.any? { |word| slur_match?(word) }
  end

  private

  def extract_words(text)
    normalized = normalize_text(text)
    normalized.split(/\s+/).reject(&:blank?)
  end

  def normalize_text(text)
    result = text.downcase
    result = result.unicode_normalize(:nfkd) if result.respond_to?(:unicode_normalize)
    result = apply_leetspeak_normalization(result)
    result.gsub(/[^a-z\s]/, "")
  end

  def apply_leetspeak_normalization(text)
    LEETSPEAK_MAP.reduce(text) { |t, (from, to)| t.gsub(from, to) }
  end

  def slur_match?(word)
    return false if word.length < MINIMUM_WORD_LENGTH

    hash = Digest::SHA256.hexdigest(word)
    SlurHashes::HASHED_SLURS.include?(hash)
  end
end
