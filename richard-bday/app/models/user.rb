class User < ApplicationRecord
  belongs_to :room
  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true

  after_commit(on: :create) { JoinRoomJob.perform_now(self) }
end
