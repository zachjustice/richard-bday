class EditorEmailChange < ApplicationRecord
  include Tokenable

  belongs_to :editor

  EXPIRY_DURATION = 24.hours

  validates :token_digest, presence: true, uniqueness: true
  validates :new_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :expires_at, presence: true

  before_validation :set_expiration, on: :create
  before_validation :normalize_new_email

  def self.create_with_token(editor:, new_email:)
    where(editor: editor, used_at: nil).update_all(used_at: Time.current)

    token = generate_token
    email_change = new(
      editor: editor,
      new_email: new_email,
      token_digest: digest(token)
    )
    email_change.save ? [ email_change, token ] : [ email_change, nil ]
  end

  def self.find_by_token(token)
    return nil if token.blank?
    find_by(token_digest: digest(token))
  end

  def valid_for_use?
    !expired? && !used?
  end

  def expired?
    expires_at < Time.current
  end

  def used?
    used_at.present?
  end

  def mark_used!
    update!(used_at: Time.current)
  end

  private

  def set_expiration
    self.expires_at ||= EXPIRY_DURATION.from_now
  end

  def normalize_new_email
    self.new_email = new_email&.downcase&.strip
  end
end
