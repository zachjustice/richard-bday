class Answer < ApplicationRecord
  DEFAULT_ANSWER = "poop"
  belongs_to :game_prompt
  belongs_to :user
  belongs_to :game

  has_many :votes, dependent: :destroy

  validates :game_prompt_id, uniqueness: { scope: [ :user_id, :game_id ] }
  validates :text,  length: { maximum: 15 }

  after_commit(on: [ :create, :update ]) { AnswerSubmittedJob.perform_later(self) }
end
