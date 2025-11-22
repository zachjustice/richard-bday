# app/helpers/stories_helper.rb
module StoriesHelper
  COLOR_CLASSES = [
    "bg-red-100",
    "bg-red-200",
    "bg-red-300",
    "bg-red-400",

    "bg-orange-100",
    "bg-orange-200",
    "bg-orange-300",
    "bg-orange-400",

    "bg-yellow-100",
    "bg-yellow-200",
    "bg-yellow-300",
    "bg-yellow-400",

    "bg-green-100",
    "bg-green-200",
    "bg-green-300",
    "bg-green-400",

    "bg-blue-100",
    "bg-blue-200",
    "bg-blue-300",
    "bg-blue-400",

    "bg-indigo-100",
    "bg-indigo-200",
    "bg-indigo-300",
    "bg-indigo-400",

    "bg-violet-100",
    "bg-violet-200",
    "bg-violet-300",
    "bg-violet-400"
  ]
  # iterate through each set of color (red 50, blue 50 etc) before moving to the next shade
  CHUNK_LENGTH = 5

  def blank_id_to_bg_color(blank_id)
    COLOR_CLASSES[(blank_id * CHUNK_LENGTH) % COLOR_CLASSES.size]
  end

  def highlight_blanks_in_text(text)
    text.gsub(/\{(\d+)\}/) do |match|
      blank_id = $1
      bg_color = blank_id_to_bg_color(blank_id.to_i)
      content_tag(:span, match, class: "blank-placeholder #{bg_color}", data: { blank_id: blank_id })
    end
  end

  def render_plaintext(text, blank_id_map)
    replacement_regex = /\{\d+\}/
    text.gsub(replacement_regex) do |match|
      answer_text, _ = blank_id_map[match]
      answer_text
    end
  end

  def render_story_with_tooltips(text, blank_id_map)
    replacement_regex = /\{\d+\}/
    # TODO handle rules for blanks or prompts. i.e. does a blank allow for punctuation in the answer?
    text.gsub(replacement_regex) do |match|
      answer_text, game_prompt_id = blank_id_map[match]
      url = ''
      if game_prompt_id 
        url = prompt_tooltip_path(game_prompt_id) 
      tag.span(
        answer_text,
        class: "game-prompt-answer",
        data: {
          controller: "prompt-tooltip",
          action: "mouseenter->prompt-tooltip#show mouseleave->prompt-tooltip#hide",
          prompt_tooltip_game_prompt_id_value: game_prompt_id,
          prompt_tooltip_url_value: url
        }
      )
    end
  end
end
