class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true
end
