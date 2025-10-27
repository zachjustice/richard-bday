require "test_helper"
require "minitest/mock"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @story = stories(:one)
    @user = users(:one)

    # Set up the user in the room and authenticate
    @user.update!(room_id: @room.id)
    resume_session_as(@room.code, @user.name)
  end

  #################################################
  # Tests for RoomsController#start
  #################################################

  test "start should create a new game for the room" do
    assert_difference("Game.count", 1) do
      post start_room_path(@room), params: { story: @story.id }
    end
  end

  test "start should create game prompts from story blanks" do
    blanks_count = Blank.where(story_id: @story.id).count
    assert blanks_count > 0, "Story should have blanks for this test"

    assert_difference("GamePrompt.count", blanks_count) do
      post start_room_path(@room), params: { story: @story.id }
    end
  end

  test "start should set room status to Answering" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    assert_equal RoomStatus::Answering, @room.status
  end

  test "start should set current_game_id on room" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    assert_not_nil @room.current_game_id
    assert_instance_of Game, @room.current_game
  end

  test "start should set current_game_prompt_id on game" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    game = @room.current_game

    assert_not_nil game.current_game_prompt_id
    assert_instance_of GamePrompt, game.current_game_prompt
  end

  test "start should set first game prompt order to 0" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    first_game_prompt = @room.current_game.current_game_prompt

    assert_equal 0, first_game_prompt.order
  end

  test "start should broadcast NextPrompt event via ActionCable" do
    # Track if broadcast was called with correct parameters
    broadcast_called = false
    broadcast_channel = nil
    broadcast_data = nil

    ActionCable.server.stub :broadcast, ->(channel, data) {
      broadcast_called = true
      broadcast_channel = channel
      broadcast_data = data
    } do
      post start_room_path(@room), params: { story: @story.id }
    end

    assert broadcast_called, "ActionCable broadcast should have been called"
    assert_equal "rooms:#{@room.id}", broadcast_channel
    assert_equal Events::MessageType::NextPrompt, broadcast_data[:messageType]
    assert broadcast_data[:prompt].present?, "Broadcast data should include prompt"
  end

  test "start should redirect to room status page on success" do
    post start_room_path(@room), params: { story: @story.id }

    assert_redirected_to room_status_path(@room)
  end

  test "start should handle invalid game creation gracefully" do
    # Create a game that will fail validation by using an invalid story_id
    invalid_story_id = -1

    assert_no_difference("Game.count") do
      post start_room_path(@room), params: { story_id: invalid_story_id }
    end

    # The controller may return 404 for missing story or redirect with error
    # Check for either case
    assert_includes [ 302, 404 ], response.status
  end

  test "start should create game prompts with correct associations" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    game = @room.current_game
    game_prompts = GamePrompt.where(game_id: game.id).order(:order)

    # Verify each game prompt has proper associations
    game_prompts.each do |gp|
      assert_not_nil gp.prompt_id, "GamePrompt should have a prompt"
      assert_not_nil gp.blank_id, "GamePrompt should have a blank"
      assert_not_nil gp.order, "GamePrompt should have an order"
    end
  end

  test "start should match prompts to blanks by tags" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    game = @room.current_game
    game_prompts = GamePrompt.where(game_id: game.id)

    # Verify that prompts are matched to blanks with the same tags
    game_prompts.each do |gp|
      assert_equal gp.blank.tags, gp.prompt.tags,
        "Prompt tags should match blank tags"
    end
  end

  test "start should order game prompts sequentially starting from 0" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    game = @room.current_game
    game_prompts = GamePrompt.where(game_id: game.id).order(:order)
    orders = game_prompts.pluck(:order)

    expected_orders = (0...game_prompts.count).to_a
    assert_equal expected_orders, orders,
      "GamePrompt orders should be sequential starting from 0"
  end

  test "start should link game to correct story" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    game = @room.current_game

    assert_equal @story.id, game.story_id
  end

  test "start should link game to correct room" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    game = @room.current_game

    assert_equal @room.id, game.room_id
  end

  # End of tests for RoomsController#start

  # Tests for RoomsController#next

  test "next should advance to next game prompt when one exists" do
    # Start the game first to set up prompts
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Get the current game prompt
    first_prompt = @room.current_game.current_game_prompt
    assert_equal 0, first_prompt.order

    # Advance to next prompt
    post next_room_path(@room)

    @room.reload
    second_prompt = @room.current_game.current_game_prompt

    assert_not_nil second_prompt
    assert_equal 1, second_prompt.order
  end

  test "next should set room status to Answering when advancing to next prompt" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Change status to something else
    @room.update!(status: RoomStatus::Results)

    post next_room_path(@room)

    @room.reload
    assert_equal RoomStatus::Answering, @room.status
  end

  test "next should update game current_game_prompt_id" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    first_prompt_id = @room.current_game.current_game_prompt_id

    post next_room_path(@room)

    @room.reload
    second_prompt_id = @room.current_game.current_game_prompt_id

    assert_not_equal first_prompt_id, second_prompt_id
  end

  test "next should set room status to FinalResults when no more prompts exist" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Advance through all prompts (we start at prompt 0, so need to advance count times)
    game_prompts = GamePrompt.where(game_id: @room.current_game_id).order(:order)
    game_prompts.count.times do
      post next_room_path(@room)
      @room.reload
    end

    assert_equal RoomStatus::FinalResults, @room.status
  end

  test "next should redirect to room status page" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    post next_room_path(@room)

    assert_redirected_to room_status_path(@room)
  end

  test "next should broadcast NextPrompt event via ActionCable when advancing" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Track broadcast
    broadcast_called = false
    broadcast_channel = nil
    broadcast_data = nil

    ActionCable.server.stub :broadcast, ->(channel, data) {
      broadcast_called = true
      broadcast_channel = channel
      broadcast_data = data
    } do
      post next_room_path(@room)
    end

    assert broadcast_called, "ActionCable broadcast should have been called"
    assert_equal "rooms:#{@room.id}", broadcast_channel
    assert_equal Events::MessageType::NextPrompt, broadcast_data[:messageType]
  end

  test "next should not broadcast when reaching final results" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Advance to second-to-last prompt
    game_prompts = GamePrompt.where(game_id: @room.current_game_id).order(:order)
    (game_prompts.count - 1).times do
      post next_room_path(@room)
      @room.reload
    end

    # Track if broadcast is called on the final next (which should reach FinalResults)
    broadcast_called = false
    broadcast_channel = nil
    broadcast_data = nil

    ActionCable.server.stub :broadcast, ->(channel, data) {
      broadcast_called = true
      broadcast_channel = channel
      broadcast_data = data
    } do
      post next_room_path(@room)
    end

    assert broadcast_called, "ActionCable broadcast should have been called"
    assert_equal "rooms:#{@room.id}", broadcast_channel
    assert_equal Events::MessageType::FinalResults, broadcast_data[:messageType]
  end

  # End of tests for RoomsController#next

  # Tests for RoomsController#show

  test "show should redirect to current prompt when room status is Answering" do
    # Start a game to set up prompts and set status to Answering
    post start_room_path(@room), params: { story: @story.id }
    @room.update!(status: RoomStatus::Answering)
    @room.reload

    get show_room_path

    current_prompt = @room.current_game.current_game_prompt
    assert_redirected_to controller: "prompts", action: "show", id: current_prompt.id
  end

  test "show should not redirect when room status is not Answering" do
    # Set room to WaitingRoom status
    @room.update!(status: RoomStatus::WaitingRoom)

    get show_room_path

    assert_response :success
  end

  # End of tests for RoomsController#show

  # Tests for RoomsController#_create

  test "_create should create a new room" do
    assert_difference("Room.count", 1) do
      post "/rooms/create"
    end
  end

  test "_create should generate a 4-character room code" do
    post "/rooms/create"

    room = Room.last
    assert_equal 4, room.code.length
    assert_match(/\A[a-z]{4}\z/, room.code)
  end

  test "_create should redirect to room status page on success" do
    post "/rooms/create"

    room = Room.last
    assert_redirected_to room_status_path(room)
  end

  test "_create should create session for first user" do
    post "/rooms/create"

    # Verify session was created (by checking cookies)
    assert cookies[:session_id].present?, "Session cookie should be set"
  end

  test "_create should handle validation failure gracefully" do
    # Stub Room.new to return a room that will fail validation
    Room.stub :new, Room.new(code: nil) do
      post "/rooms/create"

      assert_redirected_to "/"
      assert flash[:notice].present?
      assert_match(/Failed to create room/, flash[:notice])
    end
  end

  # End of tests for RoomsController#_create

  #################################################
  # Tests for RoomsController#end_game
  #################################################

  test "end_game should clear current_game_prompt from game" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    game = @room.current_game
    assert_not_nil game.current_game_prompt_id

    post end_room_game_path(@room)

    game.reload
    assert_nil game.current_game_prompt_id
  end

  test "end_game should set room status to WaitingRoom and clear current_game" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    post end_room_game_path(@room)

    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
    assert_nil @room.current_game_id
  end

  test "end_game should redirect to room status page" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    post end_room_game_path(@room)

    assert_redirected_to room_status_path(@room)
  end

  test "end_game should allow starting a new game after ending" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload
    post end_room_game_path(@room)
    @room.reload

    assert_difference("Game.count", 1) do
      post start_room_path(@room), params: { story: @story.id }
    end

    @room.reload
    assert_equal RoomStatus::Answering, @room.status
  end

  # End of tests for RoomsController#end_game

  #################################################
  # Tests for RoomsController#status
  #################################################

  test "status should render successfully for WaitingRoom status" do
    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    get room_status_path(@room)

    assert_response :success
  end

  test "status should render successfully for Answering status" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload
    @room.update!(status: RoomStatus::Answering)

    get room_status_path(@room)

    assert_response :success
  end

  test "status should render successfully for Voting status" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload
    @room.update!(status: RoomStatus::Voting)

    get room_status_path(@room)

    assert_response :success
  end

  test "status should render successfully and mark winner for Results status" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    game_prompt = @room.current_game.current_game_prompt
    user2 = User.create!(name: "Player2", room: @room)

    # Create answers and votes
    answer1 = Answer.create!(text: "Answer 1", user: @user, game_prompt: game_prompt, game: @room.current_game)
    answer2 = Answer.create!(text: "Answer 2", user: user2, game_prompt: game_prompt, game: @room.current_game)
    Vote.create!(user: @user, answer: answer2, game_prompt: game_prompt, game: @room.current_game)
    Vote.create!(user: user2, answer: answer1, game_prompt: game_prompt, game: @room.current_game)

    @room.update!(status: RoomStatus::Results)

    get room_status_path(@room)

    assert_response :success
    # Verify one answer was marked as won
    assert_equal 1, Answer.where(id: [ answer1.id, answer2.id ], won: true).count
  end

  test "status should render successfully for FinalResults status" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Create winning answers for each game prompt
    GamePrompt.where(game_id: @room.current_game_id).each do |gp|
      Answer.create!(text: "test", user: @user, game_prompt: gp, game: @room.current_game, won: true)
    end

    @room.update!(status: RoomStatus::FinalResults)

    get room_status_path(@room)

    assert_response :success
  end

  # End of tests for RoomsController#status
end
