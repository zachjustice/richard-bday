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
    text.gsub(replacement_regex) do |match|
      answer_text, game_prompt_id = blank_id_map[match]

    tag.span(
        answer_text,
        class: "game-prompt-answer",
        data: {
          controller: "game-prompt-tooltip",
          action: "mouseenter->game-prompt-tooltip#show mouseleave->game-prompt-tooltip#hide",
          game_prompt_tooltip_game_prompt_id_value: game_prompt_id,
          game_prompt_tooltip_url_value: game_prompt_tooltip_path(game_prompt_id)
        }
      )
    end
  end

  def render_story_with_bold_underline(text, blank_id_map)
    replacement_regex = /\{\d+\}/
    text.gsub(replacement_regex) do |match|
      answer_text, _ = blank_id_map[match]
      tag.strong(tag.u(answer_text), style: "font-weight: 700; text-decoration: underline; text-decoration-thickness: 2px; text-underline-offset: 2px;")
    end
  end

  # Highlight blanks in story text with popovers showing prompt info
  def highlight_blanks_with_popovers(story)
    blanks_by_id = story.blanks.includes(:prompts).index_by(&:id)

    story.text.gsub(/\{(\d+)\}/) do |match|
      blank_id = $1.to_i
      blank = blanks_by_id[blank_id]
      bg_color = blank_id_to_bg_color(blank_id)

      if blank
        prompts_text = blank.prompts.map(&:description).join("; ")
        prompts_text = "No prompts assigned" if prompts_text.blank?

        tag.span(match,
          class: "blank-placeholder cursor-help #{bg_color}",
          data: {
            blank_id: blank_id,
            controller: "blank-popover",
            action: "mouseenter->blank-popover#show mouseleave->blank-popover#hide",
            blank_popover_prompts_value: prompts_text,
            blank_popover_tags_value: blank.tags
          },
          title: prompts_text
        )
      else
        tag.span(match, class: "blank-placeholder #{bg_color}", data: { blank_id: blank_id })
      end
    end
  end
end
