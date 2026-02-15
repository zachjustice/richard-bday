require "application_system_test_case"

class AccessibilityTest < ApplicationSystemTestCase
  test "login page is accessible" do
    visit new_session_path
    assert_accessible
  end

  test "room creation page is accessible" do
    visit create_room_path
    assert_accessible
  end

  test "editor login page is accessible" do
    visit editor_login_path
    assert_accessible
  end

  test "about page is accessible" do
    visit about_path
    assert_accessible
  end

  test "copyright page is accessible" do
    visit copyright_path
    assert_accessible
  end

  test "editor forgot password page is accessible" do
    visit editor_forgot_password_path
    assert_accessible
  end

  test "editor stories page is accessible" do
    editor = editors(:one)

    visit editor_login_path
    fill_in "username", with: editor.username
    fill_in "password", with: "password123"
    click_button "Sign In"

    visit stories_path
    assert_accessible
  end
end
