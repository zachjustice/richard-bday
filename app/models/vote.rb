class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :answer
  belongs_to :prompt
  belongs_to :room

  after_commit { VoteSubmittedJob.perform_later(self) }
end
