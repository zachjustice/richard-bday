class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :answer

  after_commit { VoteSubmittedJob.perform_later(self) }
end
