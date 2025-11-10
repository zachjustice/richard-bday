# app/models/blank.rb
class Blank < ApplicationRecord
  belongs_to :story
  has_many :game_prompts, dependent: :destroy

  validates :story_id, presence: true
  validates :tags, presence: true

  # Convert comma-separated tags to array
  def tags_array
    tags.split(",").map(&:strip).reject(&:blank?)
  end

  # Find prompts matching this blank's tags
  def matching_prompts
    Prompt.where(tags: tags)
  end

  # Get placeholder text for editor display
  def placeholder_text
    "{#{id}}"
  end
end
