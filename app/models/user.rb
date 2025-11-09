class User < ApplicationRecord
  PLAYER = "Player"
  NAVIGATOR = "Navigator"
  CREATOR = "Creator"

  belongs_to :room
  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true

  # Both Player and Navigator Roles
  scope :players, -> { where(role: [ PLAYER, NAVIGATOR ]) }
  # when the room is created, the dashboard front-end gets is own "user" to auth requests with a role of Creator.
  scope :creator, -> { where(role: CREATOR) }

  after_commit(on: :create) { JoinRoomJob.perform_later(self) }
end
