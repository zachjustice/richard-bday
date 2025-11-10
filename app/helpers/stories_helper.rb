# app/helpers/stories_helper.rb
module StoriesHelper
  def highlight_blanks_in_text(text)
    text.gsub(/\{(\d+)\}/) do |match|
      blank_id = $1
      content_tag(:span, match, class: "blank-placeholder", data: { blank_id: blank_id })
    end
  end
end
