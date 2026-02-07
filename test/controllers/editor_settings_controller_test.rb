require "test_helper"

class EditorSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = editors(:one)
    @editor_session = editor_sessions(:one)
    @published_story = stories(:one)
  end

  test "show requires editor authentication" do
    get editor_settings_path
    assert_redirected_to editor_login_path
  end

  test "show renders successfully when authenticated" do
    sign_in_as_editor(@editor_session)
    get editor_settings_path

    assert_response :success
  end

  test "show displays editor username" do
    sign_in_as_editor(@editor_session)
    get editor_settings_path

    assert_select "p", text: @editor.username
  end

  test "show filters stories by search query" do
    sign_in_as_editor(@editor_session)
    get editor_settings_path, params: { query: @published_story.title }

    assert_response :success
  end

  test "show returns empty results for non-matching query" do
    sign_in_as_editor(@editor_session)
    get editor_settings_path, params: { query: "zzz_nonexistent_zzz" }

    assert_response :success
  end
end
