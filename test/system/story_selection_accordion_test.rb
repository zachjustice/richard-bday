require "application_system_test_case"

class StorySelectionAccordionTest < ApplicationSystemTestCase
  def visit_story_selection_as_creator
    visit create_room_path
    click_button "Start a Game"
    assert_text "C'MON, GET IN HERE!"
    room = Room.last
    room.update!(status: RoomStatus::StorySelection)
    visit room_status_path(room)
    wait_for_page_ready(controller: "story-selection")
    room
  end

  test "expanding voting style collapses the story section" do
    visit_story_selection_as_creator

    story_section = find("[data-story-selection-target='storySection']")
    voting_section = find("[data-story-selection-target='votingSection']")

    assert_includes story_section[:class], "accordion-section-expanded"
    refute_includes voting_section[:class], "accordion-section-expanded"

    find("[data-story-selection-target='votingSection'] .accordion-header").click

    story_section = find("[data-story-selection-target='storySection']")
    voting_section = find("[data-story-selection-target='votingSection']")
    refute_includes story_section[:class], "accordion-section-expanded"
    assert_includes voting_section[:class], "accordion-section-expanded"
  end

  test "expanding story section collapses the voting section" do
    visit_story_selection_as_creator

    find("[data-story-selection-target='votingSection'] .accordion-header").click

    voting_section = find("[data-story-selection-target='votingSection']")
    assert_includes voting_section[:class], "accordion-section-expanded"

    find("[data-story-selection-target='storySection'] .accordion-header").click

    story_section = find("[data-story-selection-target='storySection']")
    voting_section = find("[data-story-selection-target='votingSection']")
    assert_includes story_section[:class], "accordion-section-expanded"
    refute_includes voting_section[:class], "accordion-section-expanded"
  end

  test "inline max-height is cleared after expand and collapse transitions complete" do
    visit_story_selection_as_creator

    voting_content = find("[data-story-selection-target='votingSectionContent']", visible: :all)
    story_content = find("[data-story-selection-target='storySectionContent']", visible: :all)

    find("[data-story-selection-target='votingSection'] .accordion-header").click
    sleep 0.5

    refute_match(/max-height/, voting_content[:style].to_s,
      "voting content should not have inline max-height after expand animation: #{voting_content[:style]}")
    refute_match(/max-height/, story_content[:style].to_s,
      "story content should not have inline max-height after collapse animation: #{story_content[:style]}")
  end

  test "Start Game button stays inside the card when story list is long" do
    20.times do |i|
      Story.create!(title: "Filler Story #{i}", text: "A test.", original_text: "A test.", published: true)
    end

    visit_story_selection_as_creator

    button = find_button("Start Game")
    card = find(".card-primary")

    button_box = button.evaluate_script("(el => { const r = el.getBoundingClientRect(); return { top: r.top, bottom: r.bottom }; })(this)")
    card_box = card.evaluate_script("(el => { const r = el.getBoundingClientRect(); return { top: r.top, bottom: r.bottom }; })(this)")

    assert button_box["bottom"] <= card_box["bottom"] + 1,
      "Start Game button (bottom: #{button_box['bottom']}) overflowed the card (bottom: #{card_box['bottom']})"
    assert button_box["top"] >= card_box["top"] - 1,
      "Start Game button (top: #{button_box['top']}) is above the card (top: #{card_box['top']})"
  end
end
