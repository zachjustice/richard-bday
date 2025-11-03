class Answer < ApplicationRecord
  DEFAULT_ANSWER = "poop"
  belongs_to :game_prompt
  belongs_to :user
  belongs_to :game

  has_many :votes, dependent: :destroy

  after_commit(on: :create) { AnswerSubmittedJob.perform_later(self) }
end
