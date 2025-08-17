class Answer < ApplicationRecord
  belongs_to :prompt
  belongs_to :user
  belongs_to :room

  has_many :votes, dependent: :destroy
end
