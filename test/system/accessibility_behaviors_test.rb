require "application_system_test_case"

class AccessibilityBehaviorsTest < ApplicationSystemTestCase
  test "skip link exists and points to main content" do
    visit new_session_path

    # Verify skip link exists and targets #main-content
    skip_link = find("a[href='#main-content']", visible: :all)
    assert skip_link

    # Verify the target element exists and is focusable
    main = find("#main-content", visible: :all)
    assert_equal "-1", main["tabindex"]
  end

  test "mobile nav drawer opens with dialog role and closes with Escape" do
    sign_in_as_editor

    # Resize to mobile viewport to show mobile menu button
    page.driver.resize(375, 667)
    visit stories_path

    # Verify we're on the stories page
    assert_selector "button[aria-label='Toggle menu']", wait: 5

    # Open the mobile nav
    find("button[aria-label='Toggle menu']").click

    # Verify dialog attributes
    overlay = find("[role='dialog']", visible: true)
    assert_equal "true", overlay["aria-modal"]
    assert_equal "false", overlay["aria-hidden"]

    # Press Escape to close
    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")
    sleep 0.3

    # Drawer should be closed
    assert_equal "true", overlay["aria-hidden"]
  end

  test "mobile nav drawer closes when backdrop is clicked" do
    sign_in_as_editor

    page.driver.resize(375, 667)
    visit stories_path

    assert_selector "button[aria-label='Toggle menu']", wait: 5

    # Open the drawer
    find("button[aria-label='Toggle menu']").click
    overlay = find("[role='dialog']", visible: true)
    assert_equal "false", overlay["aria-hidden"]

    # Click the backdrop element (child div with click->mobile-nav#close)
    page.execute_script <<~JS
      var backdrop = document.querySelector('[role="dialog"] [data-action*="mobile-nav#close"]');
      backdrop.click();
    JS
    sleep 0.3

    assert_equal "true", overlay["aria-hidden"]
  end

  private

  def sign_in_as_editor
    editor = editors(:one)
    visit editor_login_path
    fill_in "username", with: editor.username
    fill_in "password", with: "password123"
    click_button "Sign In"
    # Wait for redirect to complete
    assert_text "Stories", wait: 5
  end
end
