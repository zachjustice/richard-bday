class EditorPasswordReset < ApplicationRecord
  include Tokenable

  belongs_to :editor

  EXPIRY_DURATION = 1.hour

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :set_expiration, on: :create

  def self.create_with_token(editor:)
    # Invalidate any existing reset tokens for this editor
    where(editor: editor, used_at: nil).update_all(used_at: Time.current)

    token = generate_token
    reset = new(
      editor: editor,
      token_digest: digest(token)
    )
    reset.save ? [ reset, token ] : [ reset, nil ]
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
end
