class User < ApplicationRecord
  include SlurFilterable

  PLAYER = "Player"
  NAVIGATOR = "Navigator"
  EDITOR = "Editor"
  CREATOR = "Creator"

  AVATARS = %w[
    🦊 🐸 🦄 🐙 🦖 🐝 🦋 🐧 🦀 🐳
    🦩 🐨 🦎 🐲 🦈 🐼 🦉 🐒 🦜 🐬
    🦁 🐢 🐿️ 🦚 🐊 🐴 🦂 🐋 🐺 🦥
    🥕 🥦 🌽 🍄 🥬 🌶️ 🥒 🍅 🧅 🥔
  ].freeze

  MAX_PLAYERS = AVATARS.size

  CREATOR_AVATAR = "🍆"

  belongs_to :room
  has_many :sessions, dependent: :destroy
  has_many :discord_activity_tokens, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true
  validates :name, uniqueness: { scope: [ :room_id ] }
  validates :name, length: { maximum: 32 }
  validates_slur_free :name
  validates :avatar, presence: true
  validates :avatar, inclusion: { in: AVATARS + [ CREATOR_AVATAR ] }
  validates :avatar, uniqueness: { scope: :room_id }
  validate :room_has_capacity, on: :create

  before_validation :assign_avatar, on: :create

  # Both Player and Navigator Roles
  scope :players, -> { where(role: [ PLAYER, NAVIGATOR ], is_active: true) }
  # when the room is created, the dashboard front-end gets is own "user" to auth requests with a role of Creator.
  scope :creator, -> { where(role: CREATOR) }

  after_commit(on: :create) { JoinRoomJob.perform_later(self) }

  def self.available_avatars(room_id)
    taken = where(room_id: room_id).where.not(avatar: nil).pluck(:avatar)
    AVATARS - taken
  end

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

  def avatar_with_name
    "#{avatar} #{name}"
  end

  private

  def room_has_capacity
    return unless player? && room_id.present?

    current_count = User.where(room_id: room_id, role: [ PLAYER, NAVIGATOR ]).count
    if current_count >= MAX_PLAYERS
      errors.add(:base, "Room is full (max #{MAX_PLAYERS} players)")
    end
  end

  def assign_avatar
    return if avatar.present?

    if creator?
      self.avatar = CREATOR_AVATAR
    else
      available = User.available_avatars(room_id)
      self.avatar = available.sample
    end
  end
end
