require "test_helper"

class StoryBlanksServiceTest < ActiveSupport::TestCase
  def setup
    @suffix = SecureRandom.hex(4)
    @story = Story.create!(
      title: "SBS #{@suffix}",
      text: "A story about blanks",
      original_text: "A story about blanks",
      published: false
    )
    @editor = Editor.create!(username: "sbs#{@suffix}", email: "sbs#{@suffix}@test.com", password: "password123", password_confirmation: "password123")
  end

  test "creates blank with new prompts successfully" do
    params = {
      tags: "noun",
      existing_prompt_ids: [],
      new_prompts: [
        { description: "SBS new prompt #{@suffix}" }
      ]
    }

    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert result.success
    assert result.blank.persisted?
    assert_equal "noun", result.blank.tags
    assert_equal 1, StoryPrompt.where(blank: result.blank).count
    assert Prompt.exists?(description: "SBS new prompt #{@suffix}")
  end

  test "creates blank with existing prompts" do
    existing = Prompt.create!(description: "SBS existing #{@suffix}", tags: "noun", creator: @editor)

    params = {
      tags: "noun",
      existing_prompt_ids: [ existing.id.to_s ],
      new_prompts: []
    }

    before_prompt_count = Prompt.count
    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert result.success
    assert_equal before_prompt_count, Prompt.count
    assert_equal 1, StoryPrompt.where(blank: result.blank, prompt: existing).count
  end

  test "creates blank with both new and existing prompts" do
    existing = Prompt.create!(description: "SBS both #{@suffix}", tags: "verb", creator: @editor)

    params = {
      tags: "verb",
      existing_prompt_ids: [ existing.id.to_s ],
      new_prompts: [
        { description: "SBS both new #{@suffix}" }
      ]
    }

    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert result.success
    assert_equal 2, StoryPrompt.where(blank: result.blank).count
  end

  test "fails when tags are blank" do
    params = {
      tags: "",
      existing_prompt_ids: [],
      new_prompts: [ { description: "SBS tag fail #{@suffix}" } ]
    }

    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert_not result.success
    assert_includes result.errors, "Tags can't be blank"
  end

  test "fails when no prompts provided" do
    params = {
      tags: "noun",
      existing_prompt_ids: [],
      new_prompts: []
    }

    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert_not result.success
    assert result.errors.any? { |e| e.include?("Must select at least one") }
  end

  test "strips whitespace from tags" do
    params = {
      tags: " noun , verb ",
      existing_prompt_ids: [],
      new_prompts: [ { description: "SBS strip #{@suffix}" } ]
    }

    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert result.success
    assert_equal "noun,verb", result.blank.tags
  end

  test "rolls back all records when prompt creation fails" do
    blank_count_before = Blank.count
    story_prompt_count_before = StoryPrompt.count

    # Pass a duplicate prompt description to trigger RecordInvalid
    Prompt.create!(description: "SBS dup #{@suffix}", tags: "noun", creator: @editor)

    params = {
      tags: "noun",
      existing_prompt_ids: [],
      new_prompts: [ { description: "SBS dup #{@suffix}" } ]
    }

    result = StoryBlanksService.new(story: @story, params: params, creator: @editor).call

    assert_not result.success
    assert_equal blank_count_before, Blank.count
    assert_equal story_prompt_count_before, StoryPrompt.count
  end
end
