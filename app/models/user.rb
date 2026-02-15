class User < ApplicationRecord
  include SlurFilterable

  PLAYER = "Player"
  NAVIGATOR = "Navigator"
  EDITOR = "Editor"
  CREATOR = "Creator"
  AUDIENCE = "Audience"

  AVATARS = %w[
    🦊 🐸 🦄 🐙 🦖 🐝 🦋 🐧 🦀 🐳
    🦩 🐨 🦎 🐲 🦈 🐼 🦉 🐒 🦜 🐬
    🦁 🐢 🐿️ 🦚 🐊 🐴 🦂 🐋 🐺 🦥
    🥕 🥦 🌽 🍄 🥬 🌶️ 🥒 🍅 🧅 🥔
  ].freeze

  MAX_PLAYERS = AVATARS.size
  MAX_AUDIENCE = 20

  CREATOR_AVATAR = "🍆"
  AUDIENCE_AVATAR = "👁️"

  belongs_to :room
  has_many :sessions, dependent: :destroy
  has_many :discord_activity_tokens, dependent: :destroy

  validates :name, presence: true
  validates :room_id, presence: true
  validates :name, uniqueness: { scope: [ :room_id ] }, unless: :audience?
  validates :name, length: { maximum: 32 }
  validates_slur_free :name
  validates :avatar, presence: true
  validates :avatar, inclusion: { in: AVATARS + [ CREATOR_AVATAR, AUDIENCE_AVATAR ] }
  validates :avatar, uniqueness: { scope: :room_id }, unless: :audience?
  validate :room_has_capacity, on: :create

  before_validation :assign_avatar, on: :create

  # Both Player and Navigator Roles
  scope :players, -> { where(role: [ PLAYER, NAVIGATOR ], is_active: true) }
  # when the room is created, the dashboard front-end gets is own "user" to auth requests with a role of Creator.
  scope :creator, -> { where(role: CREATOR) }
  scope :audience, -> { where(role: AUDIENCE) }

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

  def audience?
    role == AUDIENCE
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
    return unless room_id.present?

    if audience?
      if User.audience.where(room_id: room_id).count >= MAX_AUDIENCE
        errors.add(:base, "Audience is full (max #{MAX_AUDIENCE})")
      end
    elsif player?
      if User.where(room_id: room_id, role: [ PLAYER, NAVIGATOR ]).count >= MAX_PLAYERS
        errors.add(:base, "Room is full (max #{MAX_PLAYERS} players)")
      end
    end
  end

  def assign_avatar
    return if avatar.present?

    if creator?
      self.avatar = CREATOR_AVATAR
    elsif audience?
      self.avatar = AUDIENCE_AVATAR
    else
      available = User.available_avatars(room_id)
      self.avatar = available.sample
    end
  end
end
