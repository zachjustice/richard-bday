class Story < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  validates :original_text, presence: true
  validates :text, presence: true

  has_many :story_prompts, dependent: :destroy
  has_many :blanks, dependent: :destroy
  has_one :game

  # Parse text to find blank placeholders {blank_id}
  def blank_placeholders
    text.scan(/\{(\d+)\}/).flatten.map(&:to_i)
  end

  # Validate all blanks are used in text
  def validate_blanks
    used_blank_ids = blank_placeholders
    blank_ids = blanks.pluck(:id)

    missing = blank_ids - used_blank_ids
    unused = used_blank_ids - blank_ids

    { missing: missing, unused: unused, valid: missing.empty? && unused.empty? }
  end
end
