class Editor < ApplicationRecord
  has_secure_password
  has_many :editor_sessions, dependent: :destroy

  validates :username, presence: true, uniqueness: true
  validates :username, length: { minimum: 3, maximum: 30 }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
end
