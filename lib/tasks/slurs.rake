# frozen_string_literal: true

namespace :slurs do
  desc "Generate SHA256 hash for a word (for adding to slur list)"
  task :hash, [ :word ] => :environment do |t, args|
    word = args[:word]

    if word.blank?
      puts "Usage: rails slurs:hash[word]"
      puts "Example: rails slurs:hash[example]"
      exit 1
    end

    # Normalize the same way SlurDetectorService does
    normalized = word.to_s.downcase.strip
    hash = Digest::SHA256.hexdigest(normalized)

    puts "Word (normalized): #{normalized}"
    puts "SHA256 hash: #{hash}"
    puts ""
    puts "Add this hash to lib/slur_hashes.rb in the appropriate category."

    # Check if already in list
    if SlurHashes::HASHED_SLURS.include?(hash)
      puts ""
      puts "Note: This hash is already in the slur list."
    end
  end

  desc "Verify a word is detected by the slur filter"
  task :check, [ :word ] => :environment do |t, args|
    word = args[:word]

    if word.blank?
      puts "Usage: rails slurs:check[word]"
      exit 1
    end

    detector = SlurDetectorService.new(word)
    if detector.contains_slur?
      puts "\"#{word}\" is BLOCKED by the slur filter."
    else
      puts "\"#{word}\" is ALLOWED by the slur filter."
    end
  end
end
