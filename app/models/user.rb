class User < ApplicationRecord
  PLAYER = "Player"
  NAVIGATOR = "Navigator"
  EDITOR = "Editor"
  CREATOR = "Creator"

  belongs_to :room
  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true
  validates :name, uniqueness: { scope: [ :room_id ] }
  validates :name,  length: { maximum: 15 }

  # Both Player and Navigator Roles
  scope :players, -> { where(role: [ PLAYER, NAVIGATOR ], is_active: true) }
  # when the room is created, the dashboard front-end gets is own "user" to auth requests with a role of Creator.
  scope :creator, -> { where(role: CREATOR) }

  after_commit(on: :create) { JoinRoomJob.perform_later(self) }

  def player?
    [ PLAYER, NAVIGATOR ].include?(role)
  end

  def navigator?
    role == NAVIGATOR
  end

  def editor?
    role == EDITOR
  end

  def creator?
    role == CREATOR
  end

  def answered?
    status == UserStatus::Answered
  end

  def voted?
    status == UserStatus::Voted
  end
end
