require "test_helper"

class StoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor_one = editors(:one)
    @editor_two = editors(:two)
    @editor_session_one = editor_sessions(:one)
    @editor_session_two = editor_sessions(:two)
    @published_story = stories(:one)      # published, owned by editor_one
    @unpublished_story = stories(:two)    # unpublished, owned by editor_two
  end

  # Index tests
  test "index requires editor authentication" do
    get stories_path
    assert_redirected_to editor_login_path
  end

  test "index shows published stories and own unpublished stories" do
    sign_in_as_editor(@editor_session_one)
    get stories_path

    assert_response :success
    assert_select "h3", text: @published_story.title
    # Editor one should not see editor two's unpublished story
  end

  # Show tests
  test "show requires editor authentication" do
    get story_path(@published_story)
    assert_redirected_to editor_login_path
  end

  test "show displays published story for any editor" do
    sign_in_as_editor(@editor_session_two)
    get story_path(@published_story)

    assert_response :success
    assert_select "h1", text: @published_story.title
  end

  test "show displays unpublished story for owner" do
    sign_in_as_editor(@editor_session_two)
    get story_path(@unpublished_story)

    assert_response :success
    assert_select "h1", text: @unpublished_story.title
  end

  test "show redirects for unpublished story when not owner" do
    sign_in_as_editor(@editor_session_one)
    get story_path(@unpublished_story)

    assert_redirected_to stories_path
    assert_equal "Story not found", flash[:alert]
  end

  # Edit tests
  test "edit requires editor authentication" do
    get edit_story_path(@published_story)
    assert_redirected_to editor_login_path
  end

  test "edit allowed for story owner" do
    sign_in_as_editor(@editor_session_one)
    get edit_story_path(@published_story)

    assert_response :success
  end

  test "edit redirects non-owner" do
    sign_in_as_editor(@editor_session_two)
    get edit_story_path(@published_story)

    assert_redirected_to stories_path
    assert_equal "You are not authorized to edit this story", flash[:alert]
  end

  # Update tests
  test "update requires editor authentication" do
    patch story_path(@published_story), params: { story: { title: "New Title" } }
    assert_redirected_to editor_login_path
  end

  test "update allowed for story owner" do
    sign_in_as_editor(@editor_session_one)
    patch story_path(@published_story), params: { story: { title: "Updated Title" } }

    assert_redirected_to edit_story_path(@published_story)
    @published_story.reload
    assert_equal "Updated Title", @published_story.title
  end

  test "update redirects non-owner" do
    sign_in_as_editor(@editor_session_two)
    original_title = @published_story.title
    patch story_path(@published_story), params: { story: { title: "Hacked Title" } }

    assert_redirected_to stories_path
    @published_story.reload
    assert_equal original_title, @published_story.title
  end

  # Destroy tests
  test "destroy requires editor authentication" do
    story = Story.create!(
      title: "Deletable Story Auth",
      original_text: "Test text",
      text: "Test text",
      author: @editor_one
    )
    delete story_path(story)
    assert_redirected_to editor_login_path
  end

  test "destroy allowed for story owner" do
    sign_in_as_editor(@editor_session_one)
    # Create a fresh story to avoid foreign key issues with fixtures
    story = Story.create!(
      title: "Deletable Story",
      original_text: "Test text",
      text: "Test text",
      author: @editor_one
    )

    assert_difference("Story.count", -1) do
      delete story_path(story)
    end

    assert_redirected_to stories_path
  end

  test "destroy redirects non-owner" do
    sign_in_as_editor(@editor_session_two)
    # Create a fresh story owned by editor_one
    story = Story.create!(
      title: "Non-deletable Story",
      original_text: "Test text",
      text: "Test text",
      author: @editor_one,
      published: true
    )

    assert_no_difference("Story.count") do
      delete story_path(story)
    end

    assert_redirected_to stories_path
    assert_equal "You are not authorized to edit this story", flash[:alert]
  end

  # Create tests
  test "create sets current editor as author" do
    sign_in_as_editor(@editor_session_one)

    assert_difference("Story.count", 1) do
      post stories_path, params: {
        story: {
          title: "Brand New Story",
          original_text: "Some original text",
          text: "Some text"
        }
      }
    end

    new_story = Story.last
    assert_equal @editor_one, new_story.author
  end

  # Genre assignment tests
  test "create can assign genres to story" do
    sign_in_as_editor(@editor_session_one)
    comedy = genres(:comedy)
    horror = genres(:horror)

    post stories_path, params: {
      story: {
        title: "Genre Story",
        original_text: "A story with genres",
        text: "A story with genres",
        genre_ids: [ comedy.id, horror.id ]
      }
    }

    new_story = Story.last
    assert_includes new_story.genres, comedy
    assert_includes new_story.genres, horror
  end

  test "update can modify genres" do
    sign_in_as_editor(@editor_session_one)
    horror = genres(:horror)

    patch story_path(@published_story), params: {
      story: { genre_ids: [ horror.id ] }
    }

    @published_story.reload
    assert_includes @published_story.genres, horror
  end
end
