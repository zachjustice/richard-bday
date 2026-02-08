class CleanupExpiredTokensJob < ApplicationJob
  queue_as :default

  def perform
    cleanup_invitations
    cleanup_password_resets
    cleanup_discord_tokens
  end

  private

  def cleanup_invitations
    # Delete unaccepted invitations expired over 30 days ago
    deleted_count = EditorInvitation
      .where("expires_at < ? AND accepted_at IS NULL", 30.days.ago)
      .delete_all

    Rails.logger.info "Cleaned up #{deleted_count} expired editor invitations" if deleted_count > 0
  end

  def cleanup_password_resets
    # Delete password resets expired over 7 days ago
    deleted_count = EditorPasswordReset
      .where("expires_at < ?", 7.days.ago)
      .delete_all

    Rails.logger.info "Cleaned up #{deleted_count} expired password resets" if deleted_count > 0
  end

  def cleanup_discord_tokens
    deleted_count = DiscordActivityToken
      .where("expires_at < ?", Time.current)
      .delete_all

    Rails.logger.info "Cleaned up #{deleted_count} expired discord activity tokens" if deleted_count > 0
  end
end
