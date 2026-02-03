class Answer < ApplicationRecord
  include SlurFilterable

  DEFAULT_ANSWER = "poop"
  ANSWER_MAX_LENGTH = 150
  belongs_to :game_prompt
  belongs_to :user
  belongs_to :game

  has_many :votes, dependent: :destroy

  validates :game_prompt_id, uniqueness: { scope: [ :user_id, :game_id ] }
  validates :text, length: { maximum: Answer::ANSWER_MAX_LENGTH }
  validates_slur_free :text

  after_commit(on: [ :create, :update ]) { AnswerSubmittedJob.perform_later(self) }

  # Returns smoothed_text if available, otherwise original text.
  # Note: smoothed_text intentionally has no length validation - LLM may need
  # extra words for grammatical fit (capped at 2x original length by service).
  def display_text
    smoothed_text.presence || text
  end
end
