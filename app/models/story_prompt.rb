class StoryPrompt < ApplicationRecord
  belongs_to :story
  belongs_to :blank
  belongs_to :prompt

  validates :story_id, presence: true
  validates :blank_id, presence: true
  validates :prompt_id, presence: true
  validates :blank_id, uniqueness: { scope: [ :story_id, :prompt_id ] }
end
