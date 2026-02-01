class Story < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  validates :original_text, presence: true
  validates :text, presence: true

  belongs_to :author, class_name: "Editor", optional: true
  has_many :story_prompts, dependent: :destroy
  has_many :blanks, dependent: :destroy
  has_many :story_genres, dependent: :destroy
  has_many :genres, through: :story_genres
  has_one :game

  scope :published, -> { where(published: true) }
  scope :owned_by, ->(editor) { where(author: editor) }
  scope :visible_to, ->(editor) {
    if editor
      where(published: true).or(where(author: editor))
    else
      where(published: true)
    end
  }

  def owned_by?(editor)
    author_id == editor&.id
  end

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
