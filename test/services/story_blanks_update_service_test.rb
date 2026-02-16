require "test_helper"

class StoryBlanksUpdateServiceTest < ActiveSupport::TestCase
  def setup
    @suffix = SecureRandom.hex(4)
    @story = Story.create!(
      title: "SBUS #{@suffix}",
      text: "A story about updates",
      original_text: "A story about updates",
      published: false
    )
    @editor = Editor.create!(username: "sbus#{@suffix}", email: "sbus#{@suffix}@test.com", password: "password123", password_confirmation: "password123")
    @blank = Blank.create!(story: @story, tags: "noun")
    @existing_prompt = Prompt.create!(description: "SBUS existing #{@suffix}", tags: "noun", creator: @editor)
    StoryPrompt.create!(story: @story, blank: @blank, prompt: @existing_prompt)
  end

  test "updates blank tags" do
    params = {
      tags: "verb,adjective",
      existing_prompt_ids: [ @existing_prompt.id.to_s ],
      new_prompts: []
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert result.success
    assert_equal "verb,adjective", @blank.reload.tags
  end

  test "adds new prompts" do
    params = {
      tags: "noun",
      existing_prompt_ids: [ @existing_prompt.id.to_s ],
      new_prompts: [ { description: "SBUS new prompt #{@suffix}" } ]
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert result.success
    assert_equal 2, StoryPrompt.where(story: @story, blank: @blank).count
    assert Prompt.exists?(description: "SBUS new prompt #{@suffix}")
  end

  test "removes prompts via sync_story_prompts" do
    extra_prompt = Prompt.create!(description: "SBUS extra #{@suffix}", tags: "noun", creator: @editor)
    StoryPrompt.create!(story: @story, blank: @blank, prompt: extra_prompt)
    assert_equal 2, StoryPrompt.where(story: @story, blank: @blank).count

    # Only keep existing_prompt, removing extra_prompt
    params = {
      tags: "noun",
      existing_prompt_ids: [ @existing_prompt.id.to_s ],
      new_prompts: []
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert result.success
    assert_equal 1, StoryPrompt.where(story: @story, blank: @blank).count
    assert StoryPrompt.exists?(story: @story, blank: @blank, prompt: @existing_prompt)
    assert_not StoryPrompt.exists?(story: @story, blank: @blank, prompt: extra_prompt)
  end

  test "adds and removes prompts in the same call" do
    # Start with existing_prompt, replace it with a new one
    params = {
      tags: "noun",
      existing_prompt_ids: [],
      new_prompts: [ { description: "SBUS replacement #{@suffix}" } ]
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert result.success
    assert_equal 1, StoryPrompt.where(story: @story, blank: @blank).count
    assert_not StoryPrompt.exists?(story: @story, blank: @blank, prompt: @existing_prompt)
    new_prompt = Prompt.find_by(description: "SBUS replacement #{@suffix}")
    assert StoryPrompt.exists?(story: @story, blank: @blank, prompt: new_prompt)
  end

  test "idempotent when called twice with same params" do
    params = {
      tags: "noun",
      existing_prompt_ids: [ @existing_prompt.id.to_s ],
      new_prompts: []
    }

    result1 = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call
    sp_count_after_first = StoryPrompt.where(story: @story, blank: @blank).count

    result2 = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call
    sp_count_after_second = StoryPrompt.where(story: @story, blank: @blank).count

    assert result1.success
    assert result2.success
    assert_equal sp_count_after_first, sp_count_after_second
  end

  test "validation fails when tags are blank" do
    params = {
      tags: "",
      existing_prompt_ids: [ @existing_prompt.id.to_s ],
      new_prompts: []
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert_not result.success
    assert_includes result.errors, "Tags can't be blank"
  end

  test "validation fails when no prompts provided" do
    params = {
      tags: "noun",
      existing_prompt_ids: [],
      new_prompts: []
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert_not result.success
    assert result.errors.any? { |e| e.include?("Must select at least one") }
  end

  test "validation fails for blank new prompt descriptions" do
    params = {
      tags: "noun",
      existing_prompt_ids: [],
      new_prompts: [ { description: "   " } ]
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert_not result.success
    assert result.errors.any? { |e| e.include?("Must select at least one") }
  end

  test "transaction rolls back on failure" do
    original_tags = @blank.tags
    sp_count_before = StoryPrompt.where(story: @story, blank: @blank).count

    # Create a duplicate prompt to trigger RecordInvalid during create_new_prompts
    Prompt.create!(description: "SBUS dup #{@suffix}", tags: "noun", creator: @editor)

    params = {
      tags: "updated-tags",
      existing_prompt_ids: [],
      new_prompts: [ { description: "SBUS dup #{@suffix}" } ]
    }

    result = StoryBlanksUpdateService.new(story: @story, blank: @blank, params: params, creator: @editor).call

    assert_not result.success
    assert_equal original_tags, @blank.reload.tags, "Tags should have rolled back"
    assert_equal sp_count_before, StoryPrompt.where(story: @story, blank: @blank).count
  end
end
