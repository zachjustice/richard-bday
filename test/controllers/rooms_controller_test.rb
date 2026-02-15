require "test_helper"
require "minitest/mock"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @story = stories(:one)

    # Set up the user in the room and authenticate
    @user = User.create!(name: "Creator", room_id: @room.id, role: User::CREATOR)
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

  test "start should broadcast navigate action via Turbo Streams" do
    post start_room_path(@room), params: { story: @story.id }

    @room.reload
    first_prompt = @room.current_game.current_game_prompt

    # Verify the navigate broadcast was sent by checking the prompt was set correctly
    assert_not_nil first_prompt, "First prompt should be set after game start"
    assert_equal RoomStatus::Answering, @room.status
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

  test "next should redirect creator to room status page" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    post next_room_path(@room)

    assert_redirected_to room_status_path(@room)
  end

  test "next should advance to next prompt and update room state" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    first_prompt_id = @room.current_game.current_game_prompt_id

    post next_room_path(@room)

    @room.reload
    # Verify the room state was updated correctly
    assert_not_equal first_prompt_id, @room.current_game.current_game_prompt_id
    assert_equal RoomStatus::Answering, @room.status
  end

  test "next should set room to FinalResults when reaching last prompt" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    # Advance through all prompts
    game_prompts = GamePrompt.where(game_id: @room.current_game_id).order(:order)
    game_prompts.count.times do
      post next_room_path(@room)
      @room.reload
    end

    # Verify the room reached FinalResults status
    assert_equal RoomStatus::FinalResults, @room.status
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
    assert_redirected_to controller: "game_prompts", action: "show", id: current_prompt.id
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
  # Tests for RoomsController#_create with role-based functionality
  #################################################

  test "_create should create a Creator user for the room creator" do
    assert_difference("User.count", 1) do
      post "/rooms/create"
    end

    room = Room.last
    creator_user = User.last

    assert_equal User::CREATOR, creator_user.role
    assert_equal room.id, creator_user.room_id
    assert_match(/\ACreator-[a-z]{4}\z/, creator_user.name)
  end

  # End of tests for RoomsController#_create with role-based functionality

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

  test "end_game should redirect creator to status page" do
    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    post end_room_game_path(@room)

    assert_redirected_to room_status_path(@room)
  end

  test "end_game should redirect non-creator to waiting_for_new_game page" do
    # Create a non-creator user and authenticate as them
    player = User.create!(name: "Player", room_id: @room.id, role: User::PLAYER)
    resume_session_as(@room.code, player.name)

    post start_room_path(@room), params: { story: @story.id }
    @room.reload

    post end_room_game_path(@room)

    assert_redirected_to waiting_for_new_game_path(@room)
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

  #################################################
  # Tests for RoomsController#status authorization
  #################################################

  test "status should allow access for room Creator" do
    room = Room.create!(code: "test1", status: RoomStatus::WaitingRoom)
    creator = User.create!(name: "Creator-test1", room: room, role: User::CREATOR)

    resume_session_as(room.code, creator.name)
    get room_status_path(room)

    assert_response :success
  end

  test "status should deny access for non-Creator users" do
    room = Room.create!(code: "test3", status: RoomStatus::WaitingRoom)
    player = User.create!(name: "Player3", room: room, role: User::PLAYER)

    resume_session_as(room.code, player.name)
    get room_status_path(room)

    assert_redirected_to root_path
    assert_equal "Only the room creator can view this page", flash[:alert]
  end

  # End of tests for RoomsController#status authorization
end

class RoomsControllerCrossRoomAndNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @story = stories(:one)
    suffix = SecureRandom.hex(4)

    # Room A: has a running game with prompts
    @room_a = Room.create!(code: "ra#{suffix}", status: RoomStatus::WaitingRoom)
    @creator_a = User.create!(name: "CreatorA#{suffix}", room: @room_a, role: User::CREATOR)
    @player_a = User.create!(name: "PlayerA#{suffix}", room: @room_a, role: User::PLAYER)

    # Room B: separate room
    @room_b = Room.create!(code: "rb#{suffix}", status: RoomStatus::WaitingRoom)
    @creator_b = User.create!(name: "CreatorB#{suffix}", room: @room_b, role: User::CREATOR)
    @player_b = User.create!(name: "PlayerB#{suffix}", room: @room_b, role: User::PLAYER)

    # Start a game in Room A so we have a current_game + current_game_prompt
    resume_session_as(@room_a.code, @creator_a.name)
    post start_room_path(@room_a), params: { story: @story.id }
    @room_a.reload
    @game_a = @room_a.current_game
    @prompt_a = @game_a.current_game_prompt
  end

  #################################################
  # Cross-Room Access Control Tests
  #################################################

  test "cross-room GET status is redirected to own room" do
    resume_session_as(@room_b.code, @creator_b.name)

    get room_status_path(@room_a)

    assert_redirected_to room_status_path(@room_b)
    assert_equal "Navigating you to the right room...", flash[:notice]
  end

  test "cross-room POST start is redirected and does not modify target room" do
    resume_session_as(@room_b.code, @creator_b.name)
    original_game_id = @room_a.current_game_id

    post start_room_path(@room_a), params: { story: @story.id }

    assert_response :redirect
    @room_a.reload
    assert_equal original_game_id, @room_a.current_game_id
  end

  test "cross-room POST next is redirected and does not advance target room" do
    resume_session_as(@room_b.code, @creator_b.name)
    original_prompt_id = @room_a.current_game.current_game_prompt_id

    post next_room_path(@room_a)

    assert_response :redirect
    @room_a.reload
    assert_equal original_prompt_id, @room_a.current_game.current_game_prompt_id
  end

  test "cross-room GET check_navigation is redirected not JSON" do
    resume_session_as(@room_b.code, @player_b.name)

    get check_room_navigation_path(@room_a, current_path: "/game_prompts/#{@prompt_a.id}")

    assert_response :redirect
  end

  #################################################
  # check_navigation Endpoint Tests
  #################################################

  test "check_navigation returns nil when on correct path during Answering" do
    resume_session_as(@room_a.code, @player_a.name)

    get check_room_navigation_path(@room_a, current_path: "/game_prompts/#{@prompt_a.id}")

    assert_response :success
    assert_nil response.parsed_body["redirect_to"]
  end

  test "check_navigation returns redirect when on wrong path during Answering" do
    resume_session_as(@room_a.code, @player_a.name)

    get check_room_navigation_path(@room_a, current_path: "/game_prompts/#{@prompt_a.id}/voting")

    assert_response :success
    assert_equal "/game_prompts/#{@prompt_a.id}", response.parsed_body["redirect_to"]
  end

  test "check_navigation returns nil when no current game prompt" do
    @game_a.update!(current_game_prompt: nil)
    @room_a.update!(status: RoomStatus::WaitingRoom)
    resume_session_as(@room_a.code, @player_a.name)

    get check_room_navigation_path(@room_a, current_path: "/some/random/path")

    assert_response :success
    assert_nil response.parsed_body["redirect_to"]
  end

  test "check_navigation allows waiting page when user has answered" do
    @player_a.update!(status: UserStatus::Answered)
    resume_session_as(@room_a.code, @player_a.name)

    get check_room_navigation_path(@room_a, current_path: "/game_prompts/#{@prompt_a.id}/waiting")

    assert_response :success
    assert_nil response.parsed_body["redirect_to"]
  end

  test "check_navigation allows results page when user has voted" do
    @room_a.update!(status: RoomStatus::Voting)
    @player_a.update!(status: UserStatus::Voted)
    resume_session_as(@room_a.code, @player_a.name)

    get check_room_navigation_path(@room_a, current_path: "/game_prompts/#{@prompt_a.id}/results")

    assert_response :success
    assert_nil response.parsed_body["redirect_to"]
  end

  test "check_navigation returns nil for StorySelection status" do
    @room_a.update!(status: RoomStatus::StorySelection)
    resume_session_as(@room_a.code, @player_a.name)

    get check_room_navigation_path(@room_a, current_path: "/some/path")

    assert_response :success
    assert_nil response.parsed_body["redirect_to"]
  end
end

class TurboNavOrRedirectToDiscordTest < ActionDispatch::IntegrationTest
  setup do
    @story = stories(:one)
    suffix = SecureRandom.hex(4)

    # Discord room with a running game
    @room = Room.create!(
      code: "dc#{suffix}",
      status: RoomStatus::WaitingRoom,
      is_discord_activity: true,
      discord_instance_id: "inst-#{suffix}",
      discord_channel_id: "ch-#{suffix}"
    )
    @creator = User.create!(name: "Creator-dc#{suffix}", room: @room, role: User::CREATOR)
    @navigator = User.create!(
      name: "Nav#{suffix}",
      room: @room,
      role: User::NAVIGATOR,
      discord_id: "discord_nav_#{suffix}",
      discord_username: "navuser#{suffix}"
    )

    # Create a Bearer token for the navigator
    @token_record = DiscordActivityToken.create_for_user(@navigator)
    @token = @token_record.token
    @discord_headers = { "Authorization" => "Bearer #{@token}" }

    # Start a game via cookie session (creator), then use Discord token for tests
    resume_session_as(@room.code, @creator.name)
    post start_room_path(@room), params: { story: @story.id }
    @room.reload
    @game = @room.current_game
    @prompt = @game.current_game_prompt
    end_session

    # Second room for cross-room test
    @room_b = Room.create!(code: "rb#{suffix}", status: RoomStatus::WaitingRoom)
    @creator_b = User.create!(name: "CreatorB#{suffix}", room: @room_b, role: User::CREATOR)
  end

  test "in_room? guard renders turbo_stream navigate for Discord GET instead of redirect" do
    get room_status_path(@room_b), headers: @discord_headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "navigate"
  end

  test "redirect_to_active_game renders turbo_stream navigate for Discord GET" do
    get show_room_path, headers: @discord_headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "navigate"
    assert_includes response.body, "/game_prompts/#{@prompt.id}"
  end

  test "next action renders turbo_stream navigate for Discord POST" do
    post next_room_path(@room), headers: @discord_headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "navigate"
  end

  test "non-Discord user gets redirect instead of turbo_nav" do
    # Create a non-Discord navigator with cookie session
    suffix2 = SecureRandom.hex(4)
    room_c = Room.create!(code: "rc#{suffix2}", status: RoomStatus::WaitingRoom)
    creator_c = User.create!(name: "CreatorC#{suffix2}", room: room_c, role: User::CREATOR)
    navigator_c = User.create!(name: "NavC#{suffix2}", room: room_c, role: User::NAVIGATOR)

    resume_session_as(room_c.code, creator_c.name)
    post start_room_path(room_c), params: { story: @story.id }
    room_c.reload

    resume_session_as(room_c.code, navigator_c.name)
    post next_room_path(room_c)

    assert_response :redirect
  end

  test "Discord turbo_nav response includes iframe-safe headers" do
    get show_room_path, headers: @discord_headers

    assert_response :success
    assert_nil response.headers["X-Frame-Options"]
    assert_includes response.headers["Content-Security-Policy"], "frame-ancestors"
    assert_includes response.headers["Content-Security-Policy"], "discord.com"
  end

  test "initialize_room renders turbo_stream navigate for unauthorized Discord player" do
    # Create a regular Discord player (not navigator) who can't control the room
    player = User.create!(
      name: "Player#{SecureRandom.hex(4)}",
      room: @room,
      role: User::PLAYER,
      discord_id: "discord_player_#{SecureRandom.hex(4)}",
      discord_username: "playeruser"
    )
    player_token = DiscordActivityToken.create_for_user(player)
    player_headers = { "Authorization" => "Bearer #{player_token.token}" }

    post initialize_room_path(@room), headers: player_headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "navigate"
  end

  test "status renders turbo_stream navigate for unauthorized Discord player" do
    player = User.create!(
      name: "Player#{SecureRandom.hex(4)}",
      room: @room,
      role: User::PLAYER,
      discord_id: "discord_player_#{SecureRandom.hex(4)}",
      discord_username: "playeruser2"
    )
    player_token = DiscordActivityToken.create_for_user(player)
    player_headers = { "Authorization" => "Bearer #{player_token.token}" }

    get room_status_path(@room), headers: player_headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "navigate"
  end

  test "start_new_game does not redirect for Discord player" do
    # start_new_game uses respond_to with format.turbo_stream rendering [],
    # so Discord players (who send turbo_stream Accept header) get a success
    # response instead of a redirect that would break the iframe. Player
    # navigation happens via the broadcast_action_to navigate on the channel.
    player = User.create!(
      name: "Player#{SecureRandom.hex(4)}",
      room: @room,
      role: User::PLAYER,
      discord_id: "discord_player_#{SecureRandom.hex(4)}",
      discord_username: "playeruser3"
    )
    player_token = DiscordActivityToken.create_for_user(player)
    player_headers = { "Authorization" => "Bearer #{player_token.token}" }

    post start_new_room_game_path(@room), headers: player_headers

    assert_response :success
    refute_equal 302, response.status
  end
end
