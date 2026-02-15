require "application_system_test_case"

class RankedVotingKeyboardTest < ApplicationSystemTestCase
  setup do
    suffix = SecureRandom.hex(4)

    @room = Room.create!(code: "rv#{suffix}", status: RoomStatus::WaitingRoom, voting_style: "ranked_top_3")
    @story = Story.create!(title: "RV Story", text: "A {1} walked into a bar.", original_text: "A {1} walked into a bar.", published: true)
    @blank = Blank.create!(tags: "noun", story: @story)
    @editor = Editor.create!(username: "rv#{suffix}", email: "rv#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "Name something funny", tags: "noun", creator: @editor)
  end

  test "keyboard users can rank answers using Enter and arrow keys" do
    answers = sign_in_and_setup_voting
    visit game_prompt_voting_path(@game_prompt)
    wait_for_page_ready(controller: "ranked-voting")

    # Select the first answer with Enter
    first_answer = find("[data-answer-id='#{answers[0].id}']")
    first_answer.send_keys(:enter)

    # Answer should be visually selected
    assert_selector "[data-answer-id='#{answers[0].id}'].keyboard-selected"

    # Navigate to first slot and place with Enter
    first_slot = find("[data-rank='1']")
    first_slot.send_keys(:enter)

    # Answer should now be in the slot
    assert_selector "[data-rank='1'] [data-answer-id='#{answers[0].id}']"
  end

  test "submit button enables when all slots are filled" do
    answers = sign_in_and_setup_voting
    visit game_prompt_voting_path(@game_prompt)
    wait_for_page_ready(controller: "ranked-voting")

    # Submit should be disabled initially
    assert_selector "[data-ranked-voting-target='submit'][disabled]"

    # Fill all 3 slots using keyboard
    answers.each_with_index do |answer, i|
      place_answer_in_slot(answer.id, (i + 1).to_s)
      # Wait for answer to be placed in slot (swap animation uses setTimeout)
      assert_selector "[data-rank='#{i + 1}'] [data-answer-id='#{answer.id}']"
    end

    # Submit should now be enabled
    assert_no_selector "[data-ranked-voting-target='submit'][disabled]", wait: 2
  end

  test "Delete key removes answer from slot" do
    answers = sign_in_and_setup_voting
    visit game_prompt_voting_path(@game_prompt)
    wait_for_page_ready(controller: "ranked-voting")

    place_answer_in_slot(answers[0].id, "1")
    assert_selector "[data-rank='1'] [data-answer-id='#{answers[0].id}']"

    # Focus the slot and press Delete
    find("[data-rank='1']").send_keys(:delete)

    # Answer should be back in the container, not in the slot
    assert_no_selector "[data-rank='1'] [data-answer-id='#{answers[0].id}']"
    assert_selector "[data-ranked-voting-target='answersContainer'] [data-answer-id='#{answers[0].id}']"
  end

  test "Escape clears keyboard selection" do
    answers = sign_in_and_setup_voting
    visit game_prompt_voting_path(@game_prompt)
    wait_for_page_ready(controller: "ranked-voting")

    # Select an answer
    find("[data-answer-id='#{answers[0].id}']").send_keys(:enter)
    assert_selector "[data-answer-id='#{answers[0].id}'].keyboard-selected"

    # Press Escape
    find("[data-answer-id='#{answers[0].id}']").send_keys(:escape)

    # Selection should be cleared
    assert_no_selector ".keyboard-selected"
  end

  private

  def sign_in_and_setup_voting
    # Join the room through the form to create an authenticated session
    visit new_session_path
    fill_in "name", with: "KeyboardPlayer"
    fill_in "code", with: @room.code
    click_button "Join Game"

    player = User.find_by!(name: "KeyboardPlayer", room: @room)

    # Create other players (avatars auto-assigned from available pool)
    other1 = User.create!(name: "Other1", room: @room)
    other2 = User.create!(name: "Other2", room: @room)
    other3 = User.create!(name: "Other3", room: @room)

    # Set up the game in Voting state
    game = Game.create!(room: @room, story: @story)
    @game_prompt = GamePrompt.create!(game: game, prompt: @prompt, blank: @blank, order: 0)
    game.update!(current_game_prompt: @game_prompt)
    @room.update!(current_game: game, status: RoomStatus::Voting)

    # Create answers (player's own answer is excluded from voting page)
    Answer.create!(game: game, game_prompt: @game_prompt, user: player, text: "my answer")
    a1 = Answer.create!(game: game, game_prompt: @game_prompt, user: other1, text: "Banana")
    a2 = Answer.create!(game: game, game_prompt: @game_prompt, user: other2, text: "Cactus")
    a3 = Answer.create!(game: game, game_prompt: @game_prompt, user: other3, text: "Dinosaur")

    [ a1, a2, a3 ]
  end

  def place_answer_in_slot(answer_id, rank)
    answer = find("[data-answer-id='#{answer_id}']")
    answer.click # Focus the answer element
    answer.send_keys(:enter) # Select it
    assert_selector "[data-answer-id='#{answer_id}'].keyboard-selected", wait: 1
    slot = find("[data-rank='#{rank}']")
    slot.click # Focus the slot
    slot.send_keys(:enter) # Place the answer
  end
end
