class AnswerSmoothingJob < ApplicationJob
  queue_as :default

  # Retry on transient network/API failures
  retry_on Anthropic::Errors::APIConnectionError, wait: :polynomially_longer, attempts: 3
  retry_on Anthropic::Errors::APITimeoutError, wait: :polynomially_longer, attempts: 3
  retry_on Anthropic::Errors::InternalServerError, wait: :polynomially_longer, attempts: 3
  retry_on Anthropic::Errors::RateLimitError, wait: :polynomially_longer, attempts: 3

  def perform(answer)
    return unless answer.won?
    return if answer.smoothed_text.present?

    room = answer.game.room
    return unless room.smooth_answers?

    smoothed_text = AnswerSmoothingService.new(answer).call

    # Only update if smoothing produced different text
    if smoothed_text != answer.text
      answer.update!(smoothed_text: smoothed_text)
    end
  end
end
