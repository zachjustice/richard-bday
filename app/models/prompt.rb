# app/models/prompt.rb
class Prompt < ApplicationRecord
  has_many :game_prompts, dependent: :destroy

  validates :description, presence: true, uniqueness: true
  validates :tags, presence: true

  # Convert comma-separated tags to array
  def tags_array
    tags.split(",").map(&:strip).reject(&:blank?)
  end

  # Find blanks matching this prompt's tags
  def matching_blanks
    Blank.where(tags: tags)
  end
end
