class AnswerSmoothingService
  MIN_SENTENCE_WORDS = 2
  MODEL = "claude-3-5-haiku-latest"

  def initialize(answer)
    @answer = answer
    @game_prompt = answer.game_prompt
    @blank = @game_prompt.blank
    @story = @game_prompt.game.story
  end

  def call
    return @answer.text unless smoothing_enabled?

    context = extract_context
    smoothed = generate_smoothed_text(context)

    smoothed.presence || @answer.text
  rescue StandardError => e
    Rails.logger.error("[AnswerSmoothingService] Failed for answer #{@answer.id}: #{e.message}")
    @answer.text
  end

  private

  def smoothing_enabled?
    @answer.game.room.smooth_answers?
  end

  def extract_context
    story_text = @story.text
    placeholder = "{#{@blank.id}}"

    return { before: "", after: "", prompt: @game_prompt.prompt.description } unless story_text.include?(placeholder)

    sentences = split_into_sentences(story_text, placeholder)
    current_idx = sentences.index { |s| s.include?(placeholder) }

    return { before: "", after: "", prompt: @game_prompt.prompt.description } unless current_idx

    current_sentence = sentences[current_idx]
    word_count = current_sentence.split.size

    if word_count < MIN_SENTENCE_WORDS
      # Include adjacent sentences for more context
      before_sentence = current_idx > 0 ? sentences[current_idx - 1] : ""
      after_sentence = current_idx < sentences.size - 1 ? sentences[current_idx + 1] : ""
      context_sentence = [ before_sentence, current_sentence, after_sentence ].map(&:strip).reject(&:empty?).join(" ")
    else
      context_sentence = current_sentence
    end

    # Split context around the placeholder
    parts = context_sentence.split(placeholder, 2)
    before = parts[0]&.strip || ""
    after = parts[1]&.strip || ""

    {
      before: before,
      after: after,
      prompt: @game_prompt.prompt.description
    }
  end

  def split_into_sentences(text, placeholder)
    # Temporarily replace placeholder to avoid splitting issues
    temp_marker = "\x00BLANK\x00"
    temp_text = text.gsub(placeholder, temp_marker)

    # Split on sentence boundaries (. ! ?) followed by whitespace or end
    sentences = temp_text.split(/(?<=[.!?])\s+/)

    # Restore placeholder
    sentences.map { |s| s.gsub(temp_marker, placeholder) }
  end

  def generate_smoothed_text(context)
    client = anthropic_client

    system_prompt = <<~PROMPT
      You are a grammar assistant for a fill-in-the-blank party game. Your job is to adapt
      player answers to fit grammatically into sentences while preserving the original
      meaning and humor.

      The player answer will be in [[double square brackets.]]

      Return answers in an xml block:
      <answer>
      your answer here
      </answer>

      Rules:
        - Make the SIMPLEST, MINIMAL changes - only adjust verb tense, articles, pronouns, punctuation, or word forms as needed
        - Preserve any intentional humor, absurdity, or creative phrasing
        - NEVER censor or sanitize
        - NEVER add explanations or commentary
        - If the answer cannot be adapted to fit grammatically, then return an empty string.
        - In the event of an error, return ONLY an empty string
        - If no changes are needed, return the original text exactly
    PROMPT

    sentence = "#{context[:before]} [[#{@answer.text}]] #{context[:after]}"
    user_prompt = <<~PROMPT
      If possible, adapt the answer to the following sentence:
      #{sentence}
    PROMPT

    Rails.logger.debug("Attempting to smooth:\n#{user_prompt}")
    response = client.messages.create(
      model: MODEL,
      max_tokens: 200,
      system: system_prompt,
      messages: [ { role: "user", content: user_prompt } ]
    )
    raw_response = response.content.first.text
    Rails.logger.debug("ANTHROPIC RESPONSE:\n#{raw_response&.strip}")


    parsed = parse_answer_from_response(raw_response)

    # Return early if the LLM simply echoes back the _entire_ sentence instead of only the smoothed answer.
    return if parsed&.strip == sentence.strip
    # LLM responses longer than twice the original answer length are probably wrong
    return if parsed && parsed.length >= @answer.text.length * 2

    parsed
  end

  def parse_answer_from_response(response_text)
    return nil if response_text.blank?

    # Extract content between <answer> tags
    match = response_text.match(%r{<answer>\s*(.*?)\s*</answer>}m)
    return nil unless match

    match[1].strip.presence
  end

  def anthropic_client
    Anthropic::Client.new(api_key: api_key)
  end

  def api_key
    key = Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]
    raise "Anthropic API key not configured. Set ANTHROPIC_API_KEY or add to credentials." unless key
    key
  end
end
