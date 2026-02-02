require "test_helper"

class PromptsEditorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor_one = editors(:one)
    @editor_two = editors(:two)
    @editor_session_one = editor_sessions(:one)
    @editor_session_two = editor_sessions(:two)
    @prompt_one = prompts(:one)   # owned by editor_one
    @prompt_two = prompts(:two)   # owned by editor_two
    @prompt_three = prompts(:three) # no creator
  end

  # Index tests
  test "prompts index requires editor authentication" do
    get prompts_index_path
    assert_redirected_to editor_login_path
  end

  test "prompts index displays all prompts for authenticated editor" do
    sign_in_as_editor(@editor_session_one)
    get prompts_index_path

    assert_response :success
  end

  # Create tests
  test "create_prompt requires editor authentication" do
    post create_prompt_path, params: {
      prompt: { description: "Test prompt", tags: "test" }
    }
    assert_redirected_to editor_login_path
  end

  test "create_prompt sets current editor as creator" do
    sign_in_as_editor(@editor_session_one)

    assert_difference("Prompt.count", 1) do
      post create_prompt_path, params: {
        prompt: { description: "Brand new prompt", tags: "new,test" }
      }
    end

    new_prompt = Prompt.last
    assert_equal @editor_one, new_prompt.creator
  end

  # Edit tests
  # Note: edit_prompt is typically accessed via turbo frames in the index page,
  # so we only test authorization behavior here

  test "edit_prompt requires editor authentication" do
    get edit_prompt_path(@prompt_one)
    assert_redirected_to editor_login_path
  end

  test "edit_prompt forbidden for non-creator" do
    sign_in_as_editor(@editor_session_two)
    get edit_prompt_path(@prompt_one)

    assert_redirected_to prompts_index_path
    assert_equal "You are not authorized to edit this prompt", flash[:alert]
  end

  # Update tests
  test "update_prompt requires editor authentication" do
    patch update_prompt_path(@prompt_one), params: {
      prompt: { description: "Updated" }
    }
    assert_redirected_to editor_login_path
  end

  test "update_prompt allowed for prompt creator" do
    sign_in_as_editor(@editor_session_one)
    patch update_prompt_path(@prompt_one), params: {
      prompt: { description: "Updated description" }
    }

    assert_redirected_to prompts_index_path
    @prompt_one.reload
    assert_equal "Updated description", @prompt_one.description
  end

  test "update_prompt forbidden for non-creator" do
    sign_in_as_editor(@editor_session_two)
    original_description = @prompt_one.description
    patch update_prompt_path(@prompt_one), params: {
      prompt: { description: "Hacked description" }
    }

    assert_redirected_to prompts_index_path
    @prompt_one.reload
    assert_equal original_description, @prompt_one.description
  end

  # Destroy tests
  test "destroy_prompt requires editor authentication" do
    # Create a fresh prompt to avoid foreign key issues
    prompt = Prompt.create!(description: "Deletable prompt", tags: "test", creator: @editor_one)
    delete destroy_prompt_path(prompt)
    assert_redirected_to editor_login_path
  end

  test "destroy_prompt allowed for prompt creator" do
    sign_in_as_editor(@editor_session_one)
    # Create a fresh prompt to avoid foreign key issues with fixtures
    prompt = Prompt.create!(description: "Deletable prompt", tags: "test", creator: @editor_one)

    assert_difference("Prompt.count", -1) do
      delete destroy_prompt_path(prompt)
    end

    assert_redirected_to prompts_index_path
  end

  test "destroy_prompt forbidden for non-creator" do
    sign_in_as_editor(@editor_session_two)
    # Create a fresh prompt owned by editor_one
    prompt = Prompt.create!(description: "Another deletable prompt", tags: "test", creator: @editor_one)

    assert_no_difference("Prompt.count") do
      delete destroy_prompt_path(prompt)
    end

    assert_redirected_to prompts_index_path
  end

  # Prompt with no creator tests
  test "prompt with no creator cannot be updated by anyone" do
    sign_in_as_editor(@editor_session_one)
    # Create a fresh prompt with no creator
    prompt = Prompt.create!(description: "No creator editable prompt", tags: "test", creator: nil)
    original_description = prompt.description

    patch update_prompt_path(prompt), params: {
      prompt: { description: "Hacked description" }
    }

    assert_redirected_to prompts_index_path
    prompt.reload
    assert_equal original_description, prompt.description
  end

  test "prompt with no creator cannot be deleted by anyone" do
    sign_in_as_editor(@editor_session_one)
    # Create a fresh prompt with no creator
    prompt = Prompt.create!(description: "No creator prompt", tags: "test", creator: nil)

    assert_no_difference("Prompt.count") do
      delete destroy_prompt_path(prompt)
    end

    assert_redirected_to prompts_index_path
  end
end
