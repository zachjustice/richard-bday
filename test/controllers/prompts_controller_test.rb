require "test_helper"

class PromptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
    @prompt = prompts(:one)
    sign_in_as_editor(@editor)
  end

  # Tests for PromptsController#index

  test "index should display prompts list" do
    get "/prompts"

    assert_response :success
    assert_select "body"
  end

  test "index should require editor authentication" do
    sign_out_editor

    get "/prompts"

    assert_response :redirect
  end

  # Tests for PromptsController#new

  test "new should display new prompt form" do
    get "/prompts/new"

    assert_response :success
  end

  test "new should require editor authentication" do
    sign_out_editor

    get "/prompts/new"

    assert_response :redirect
  end

  # Tests for PromptsController#create_prompt

  test "create_prompt should create a new prompt" do
    assert_difference("Prompt.count", 1) do
      post "/prompts", params: {
        prompt: {
          description: "New test prompt description",
          tags: "tag1, tag2"
        }
      }
    end
  end

  test "create_prompt should assign current editor as creator" do
    post "/prompts", params: {
      prompt: {
        description: "Prompt with creator",
        tags: "test"
      }
    }

    new_prompt = Prompt.last
    assert_equal @editor.id, new_prompt.creator_id
  end

  test "create_prompt should require editor authentication" do
    sign_out_editor

    assert_no_difference("Prompt.count") do
      post "/prompts", params: {
        prompt: {
          description: "Should not be created",
          tags: "test"
        }
      }
    end

    assert_response :redirect
  end

  test "create_prompt should not create prompt with invalid params" do
    assert_no_difference("Prompt.count") do
      post "/prompts", params: {
        prompt: {
          description: "",
          tags: ""
        }
      }
    end
  end

  # Tests for PromptsController#edit_prompt

  test "edit_prompt should display edit form for owned prompt" do
    @prompt.update!(creator: @editor)

    get "/prompts/#{@prompt.id}/edit"

    assert_response :success
  end

  test "edit_prompt should not allow editing prompt owned by another editor" do
    other_editor = editors(:two)
    @prompt.update!(creator: other_editor)

    get "/prompts/#{@prompt.id}/edit"

    assert_response :redirect
  end

  test "edit_prompt should require editor authentication" do
    sign_out_editor

    get "/prompts/#{@prompt.id}/edit"

    assert_response :redirect
  end

  # Tests for PromptsController#update_prompt

  test "update_prompt should update owned prompt" do
    @prompt.update!(creator: @editor)

    patch "/prompts/#{@prompt.id}", params: {
      prompt: {
        description: "Updated description",
        tags: "updated, tags"
      }
    }

    @prompt.reload
    assert_equal "Updated description", @prompt.description
    assert_equal "updated, tags", @prompt.tags
  end

  test "update_prompt should not update prompt owned by another editor" do
    other_editor = editors(:two)
    @prompt.update!(creator: other_editor)
    original_description = @prompt.description

    patch "/prompts/#{@prompt.id}", params: {
      prompt: {
        description: "Should not update"
      }
    }

    @prompt.reload
    assert_equal original_description, @prompt.description
  end

  test "update_prompt should require editor authentication" do
    sign_out_editor

    patch "/prompts/#{@prompt.id}", params: {
      prompt: {
        description: "Should not update"
      }
    }

    assert_response :redirect
  end

  # Tests for PromptsController#destroy_prompt

  test "destroy_prompt should delete owned prompt" do
    # Create a fresh prompt without foreign key dependencies
    prompt = Prompt.create!(description: "Deletable prompt", tags: "test", creator: @editor)

    assert_difference("Prompt.count", -1) do
      delete "/prompts/#{prompt.id}"
    end
  end

  test "destroy_prompt should not delete prompt owned by another editor" do
    other_editor = editors(:two)
    @prompt.update!(creator: other_editor)

    assert_no_difference("Prompt.count") do
      delete "/prompts/#{@prompt.id}"
    end
  end

  test "destroy_prompt should require editor authentication" do
    sign_out_editor

    assert_no_difference("Prompt.count") do
      delete "/prompts/#{@prompt.id}"
    end

    assert_response :redirect
  end
end
