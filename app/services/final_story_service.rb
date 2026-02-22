class FinalStoryService
  def initialize(game)
    @game = game
  end

  def call
    story_text = @game.story.text
    winning_answers = Answer.where(game_id: @game.id, won: true)
    blank_id_to_answer_text = winning_answers.reduce({}) do |result, ans|
      result["{#{ans.game_prompt.blank.id}}"] = [ ans.display_text, ans.game_prompt.id ]
      result
    end

    replacement_regex = /\{\d+\}/
    complete_story = story_text.gsub(replacement_regex, blank_id_to_answer_text)
    validate_story(complete_story, blank_id_to_answer_text, story_text, replacement_regex)

    {
      story_text: story_text,
      blank_id_to_answer_text: blank_id_to_answer_text
    }
  end

  private

  def validate_story(complete_story, blank_id_to_answer_text, story_text, replacement_regex)
    includes_leftover_regex = complete_story.match?(replacement_regex)
    missing_answers = blank_id_to_answer_text.values.reject { |ans| complete_story.include?(ans.first) }

    if includes_leftover_regex || !missing_answers.empty?
      error_part1 = includes_leftover_regex ? "[LEFTOVER_REGEX]" : ""
      error_part2 = !missing_answers.empty? ? "[MISSING_ANSWERS]" : ""
      Rails.logger.error(
        "[FinalStoryService#validate_story] Generated invalid story! #{error_part1}#{error_part2} " \
        "missing_answers: `#{missing_answers.to_json}`, StoryId: #{@game.story.id}, " \
        "story_text: `#{story_text}`, complete_story: `#{complete_story}`"
      )
    end
  end
end
