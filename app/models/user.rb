class User < ApplicationRecord
  PLAYER = "Player"
  CREATOR = "Creator"

  belongs_to :room
  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true

  scope :players, -> { where(role: PLAYER) }
  scope :creator, -> { where(role: CREATOR) }

  after_commit(on: :create) { JoinRoomJob.perform_later(self) }
end
