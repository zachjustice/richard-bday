require "test_helper"

class BlanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
    @editor_session = editor_sessions(:one)
    @story = stories(:one)
    @blank = blanks(:one)
    @prompt = prompts(:one)
  end

  test "requires editor authentication" do
    post story_blanks_path(@story), params: {
      blank: { tags: "noun", new_prompts: [ { description: "Name something" } ] }
    }
    assert_redirected_to editor_login_path
  end

  test "create with valid params returns turbo stream and closes modal" do
    sign_in_as_editor(@editor_session)

    assert_difference("Blank.count", 1) do
      post story_blanks_path(@story), params: {
        blank: {
          tags: "animal,noun",
          new_prompts: [ { description: "Name a pet" } ]
        }
      }, as: :turbo_stream
    end

    assert_response :success
  end

  test "create with missing tags re-renders with error" do
    sign_in_as_editor(@editor_session)

    assert_no_difference("Blank.count") do
      post story_blanks_path(@story), params: {
        blank: {
          tags: "",
          new_prompts: [ { description: "Name a pet" } ]
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match(/blank-modal-form/, response.body)
  end

  test "create with no prompts re-renders with error" do
    sign_in_as_editor(@editor_session)

    assert_no_difference("Blank.count") do
      post story_blanks_path(@story), params: {
        blank: {
          tags: "noun"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match(/blank-modal-form/, response.body)
  end

  test "edit renders turbo stream with blank data" do
    sign_in_as_editor(@editor_session)

    get edit_story_blank_path(@story, @blank), as: :turbo_stream

    assert_response :success
    assert_match(/blank-modal-form/, response.body)
  end

  test "update with valid params replaces blank partial" do
    sign_in_as_editor(@editor_session)

    patch story_blank_path(@story, @blank), params: {
      blank: {
        tags: "adjective",
        existing_prompt_ids: [ @prompt.id.to_s ]
      }
    }, as: :turbo_stream

    assert_response :success
    @blank.reload
    assert_equal "adjective", @blank.tags
  end

  test "update with invalid params re-renders form and preserves original tags" do
    sign_in_as_editor(@editor_session)
    original_tags = @blank.tags

    patch story_blank_path(@story, @blank), params: {
      blank: {
        tags: "",
        existing_prompt_ids: [ @prompt.id.to_s ]
      }
    }, as: :turbo_stream

    assert_response :success
    assert_match(/blank-modal-form/, response.body)
    assert_equal original_tags, @blank.reload.tags
  end

  test "destroy removes blank via turbo stream" do
    sign_in_as_editor(@editor_session)
    blank = Blank.create!(tags: "test", story: @story)

    assert_difference("Blank.count", -1) do
      delete story_blank_path(@story, blank), as: :turbo_stream
    end

    assert_response :success
  end
end
