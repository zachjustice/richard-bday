# app/models/prompt.rb
class Prompt < ApplicationRecord
  include SlurFilterable

  belongs_to :creator, class_name: "Editor"
  has_many :game_prompts, dependent: :destroy
  has_many :story_prompts, dependent: :destroy

  validates :description, presence: true, uniqueness: true
  validates :tags, presence: true
  validates_slur_free :description, :tags

  def owned_by?(editor)
    creator_id == editor&.id
  end

  # Convert comma-separated tags to array
  def tags_array
    tags.split(",").map(&:strip).reject(&:blank?)
  end

  # Find blanks matching this prompt's tags
  def matching_blanks
    Blank.where(tags: tags)
  end
end
