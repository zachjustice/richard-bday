class Editor < ApplicationRecord
  has_secure_password
  has_many :editor_sessions, dependent: :destroy
  has_many :editor_password_resets, dependent: :destroy
  has_one :editor_invitation, dependent: :nullify
  has_many :stories, foreign_key: :author_id, dependent: :nullify, inverse_of: :author
  has_many :prompts, foreign_key: :creator_id, dependent: :nullify, inverse_of: :creator

  validates :username, presence: true, uniqueness: true
  validates :username, length: { minimum: 3, maximum: 30 }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :email, presence: true, uniqueness: { message: "is already registered" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be valid" }

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
