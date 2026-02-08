class DiscordActivityToken < ApplicationRecord
  include Tokenable

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  TOKEN_LIFETIME = 24.hours

  def self.create_for_user(user)
    token = generate_token
    record = create!(
      user: user,
      token_digest: digest(token),
      expires_at: TOKEN_LIFETIME.from_now
    )
    record.instance_variable_set(:@token, token)
    record
  end

  def self.find_by_token(token)
    return nil if token.blank?
    find_by(token_digest: digest(token))
  end

  def token
    @token
  end

  def valid_token?
    expires_at > Time.current
  end

  def refresh!
    update!(expires_at: TOKEN_LIFETIME.from_now)
  end
end
