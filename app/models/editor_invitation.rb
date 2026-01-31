class EditorInvitation < ApplicationRecord
  include Tokenable

  belongs_to :editor, optional: true

  EXPIRY_DURATION = 3.days

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :set_expiration, on: :create

  def self.create_with_token(email:)
    token = generate_token
    invitation = new(
      email: email.downcase.strip,
      token_digest: digest(token)
    )
    invitation.save ? [ invitation, token ] : [ invitation, nil ]
  end

  def self.find_by_token(token)
    return nil if token.blank?
    find_by(token_digest: digest(token))
  end

  def valid_for_use?
    !expired? && !accepted?
  end

  def expired?
    expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def mark_accepted!(editor)
    update!(accepted_at: Time.current, editor: editor)
  end

  private

  def set_expiration
    self.expires_at ||= EXPIRY_DURATION.from_now
  end
end
