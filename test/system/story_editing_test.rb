require "application_system_test_case"

class StoryEditingTest < ApplicationSystemTestCase
  setup do
    sign_in_as_editor
    @story = stories(:one)
    @blank_one = blanks(:one)
    @prompt_one = prompts(:one)
  end

  # --- Story Form ---

  test "editor can view story edit page with pre-filled fields" do
    visit edit_story_path(@story)

    assert_field "Story Title", with: @story.title
    assert_field "Story Text (with blanks)", with: @story.text
    assert_field "Original Text (for reference)", with: @story.original_text
  end

  test "editor can update story" do
    visit edit_story_path(@story)

    fill_in "Story Title", with: "Updated Title"
    click_button "Update Story"

    assert_text "Story updated successfully", wait: 5
  end

  test "story form shows validation errors" do
    visit edit_story_path(@story)

    # Browser required attribute blocks empty submission, so bypass it via JS
    page.execute_script("document.querySelector('input[name=\"story[title]\"]').removeAttribute('required')")
    fill_in "Story Title", with: ""
    click_button "Update Story"

    assert_text "Please fix the following errors", wait: 5
  end

  # --- Blank Modal ---

  test "Add Blank button opens modal" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"

    modal = find("#blank-editor-modal")
    assert_equal "false", modal["aria-hidden"]
  end

  test "modal closes via close button" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    modal = find("#blank-editor-modal")
    assert_equal "false", modal["aria-hidden"]

    find("button[aria-label='Close']").click

    assert_selector "#blank-editor-modal[aria-hidden='true']", visible: :all, wait: 2
  end

  test "modal closes via Escape key" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    modal = find("#blank-editor-modal")
    assert_equal "false", modal["aria-hidden"]

    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")

    assert_selector "#blank-editor-modal[aria-hidden='true']", visible: :all, wait: 2
  end

  # --- Blank Form Validation ---

  test "submitting blank form without selection shows validation hint" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    wait_for_page_ready(controller: "blank-form")

    fill_in "Tags (comma-separated)", with: "animal,noun"
    assert_selector ".prompt-checkbox", wait: 5

    click_button "Create Blank"

    assert_selector "[data-blank-form-target='validationHint']", visible: true, wait: 3
  end

  test "validation hint clears when prompt is selected after failed submit" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    wait_for_page_ready(controller: "blank-form")

    fill_in "Tags (comma-separated)", with: "animal,noun"
    assert_selector ".prompt-checkbox", wait: 5

    click_button "Create Blank"
    assert_selector "[data-blank-form-target='validationHint']", visible: true, wait: 3

    first(".prompt-checkbox input[type='checkbox']").check

    assert_no_selector "[data-blank-form-target='validationHint']", visible: true
  end

  test "no validation hint before first submit attempt" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    wait_for_page_ready(controller: "blank-form")

    fill_in "Tags (comma-separated)", with: "animal,noun"
    assert_selector ".prompt-checkbox", wait: 5

    assert_no_selector "[data-blank-form-target='validationHint']", visible: true
  end

  # --- Blank CRUD ---

  test "create blank with existing prompt" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    wait_for_page_ready(controller: "blank-form")

    fill_in "Tags (comma-separated)", with: "animal,noun"
    assert_selector ".prompt-checkbox", wait: 5

    first(".prompt-checkbox input[type='checkbox']").check
    click_button "Create Blank"

    assert_text "Successfully created Blank", wait: 5

    # Modal closed (hidden class added by turbo stream)
    modal = find("#blank-editor-modal", visible: :all)
    assert_includes modal[:class], "hidden"
  end

  test "create blank with new prompt" do
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    wait_for_page_ready(controller: "blank-form")

    fill_in "Tags (comma-separated)", with: "food,noun"
    click_button "+ Add New Prompt"

    # Fill the new prompt textarea via JS to ensure the value is set
    page.execute_script("document.querySelector('[data-blank-form-target=\"newPromptInput\"]').value = 'Name your favorite food'")

    click_button "Create Blank"

    assert_text "Successfully created Blank", wait: 5

    modal = find("#blank-editor-modal", visible: :all)
    assert_includes modal[:class], "hidden"
  end

  test "edit blank opens modal with pre-filled data" do
    visit edit_story_path(@story)

    within "#blank_#{@blank_one.id}" do
      find("button[title='Edit']").click
    end

    # Modal opens via custom turbo stream action (sets hidden class, not aria-hidden)
    assert_text "Edit Blank #{@blank_one.id}", wait: 5
    modal = find("#blank-editor-modal", visible: true)
    assert_not_includes modal[:class], "hidden"
  end

  test "delete blank removes it from list" do
    # Create a fresh blank first (avoids FK cascade issues with fixtures)
    visit edit_story_path(@story)

    click_button "+ Add Blank"
    wait_for_page_ready(controller: "blank-form")

    fill_in "Tags (comma-separated)", with: "food,noun"
    click_button "+ Add New Prompt"
    page.execute_script("document.querySelector('[data-blank-form-target=\"newPromptInput\"]').value = 'Name a food'")
    click_button "Create Blank"
    assert_text "Successfully created Blank", wait: 5

    # Find the newly created blank (last one in the list)
    new_blank = all("#blanks_list .blank-item").last
    new_blank_id = new_blank[:id]

    accept_confirm do
      within "##{new_blank_id}" do
        find("button[title='Delete']").click
      end
    end

    assert_no_selector "##{new_blank_id}", wait: 5
  end

  # --- Inline Prompt Editing ---

  test "editor can edit owned prompt inline" do
    visit edit_story_path(@story)

    within "#prompt_#{@prompt_one.id}" do
      find("button[title='Edit prompt']").click
    end

    # Wait for form animation to complete
    sleep 0.6

    within "#prompt_#{@prompt_one.id}" do
      fill_in "prompt[description]", with: "Updated prompt text"
      click_button "Save"
    end

    assert_text "Updated prompt text", wait: 5
  end

  test "editor can cancel prompt edit" do
    visit edit_story_path(@story)

    within "#prompt_#{@prompt_one.id}" do
      find("button[title='Edit prompt']").click
    end

    sleep 0.6

    within "#prompt_#{@prompt_one.id}" do
      click_button "Cancel"
    end

    sleep 0.6

    within "#prompt_#{@prompt_one.id}" do
      assert_text @prompt_one.description
    end
  end

  private

  def sign_in_as_editor
    editor = editors(:one)
    visit editor_login_path
    fill_in "username", with: editor.username
    fill_in "password", with: "password123"
    click_button "Sign In"
    assert_text "Stories", wait: 5
  end
end
