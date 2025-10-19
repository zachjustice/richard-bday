class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :answer
  belongs_to :game
  belongs_to :game_prompt


  after_commit(on: :create) { VoteSubmittedJob.perform_later(self) }
end
