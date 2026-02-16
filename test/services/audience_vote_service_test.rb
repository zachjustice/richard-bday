require "test_helper"
require "minitest/mock"

class AudienceVoteServiceTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors from after_commit callbacks
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "av#{suffix}", status: RoomStatus::Voting, voting_style: "vote_once")
    @story = Story.create!(title: "AV #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @editor = Editor.create!(username: "av#{suffix}", email: "av#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @blank = Blank.create!(story: @story, tags: "noun")
    @prompt = Prompt.create!(description: "AV prompt #{suffix}", tags: "noun", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    @player1 = User.create!(name: "P1#{suffix}", room: @room, role: User::PLAYER)
    @player2 = User.create!(name: "P2#{suffix}", room: @room, role: User::PLAYER)
    @audience = User.create!(name: "A#{suffix}", room: @room, role: User::AUDIENCE)

    @answer1 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player1, text: "answer1")
    @answer2 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player2, text: "answer2")
  end

  test "valid submission creates votes and returns success" do
    stars = { @answer1.id.to_s => "3", @answer2.id.to_s => "2" }

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Success, result
    assert_equal 5, Vote.where(user: @audience, game_prompt: @game_prompt).count
    assert_equal 3, Vote.where(user: @audience, answer: @answer1).count
    assert_equal 2, Vote.where(user: @audience, answer: @answer2).count
  end

  test "accepts ActionController::Parameters as stars_params" do
    stars = ActionController::Parameters.new(@answer1.id.to_s => "2", @answer2.id.to_s => "1")

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Success, result
    assert_equal 3, Vote.where(user: @audience, game_prompt: @game_prompt).count
  end

  test "invalid params returns failure" do
    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: "not_a_hash", room: @room
    ).call

    assert_kind_of AudienceVoteService::Failure, result
    assert_nil result.error
  end

  test "duplicate submission returns already counted message" do
    stars = { @answer1.id.to_s => "3" }

    first = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call
    assert_kind_of AudienceVoteService::Success, first

    second = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call
    assert_kind_of AudienceVoteService::Failure, second
    assert_equal "Your stars for this round were already counted!", second.error
  end

  test "star values are clamped to max" do
    stars = { @answer1.id.to_s => "10" }

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Success, result
    assert_equal Vote::MAX_AUDIENCE_STARS, Vote.where(user: @audience, game_prompt: @game_prompt).count
  end

  test "total stars exceeding max returns failure" do
    stars = {
      @answer1.id.to_s => Vote::MAX_AUDIENCE_STARS.to_s,
      @answer2.id.to_s => "1"
    }

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Failure, result
  end

  test "zero total stars returns failure" do
    stars = { @answer1.id.to_s => "0", @answer2.id.to_s => "0" }

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Failure, result
  end

  test "invalid answer ids returns failure" do
    stars = { "999999" => "3" }

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Failure, result
  end

  test "invalid game_prompt_id returns failure" do
    stars = { @answer1.id.to_s => "3" }

    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: 999999,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Failure, result
  end

  test "DB failure in create_votes rolls back transaction, allowing retry" do
    stars = { @answer1.id.to_s => "3" }

    # First call: force a DB failure inside the transaction
    Vote.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(Vote.new) }) do
      result = AudienceVoteService.new(
        user: @audience, game_prompt_id: @game_prompt.id,
        stars_params: stars, room: @room
      ).call

      assert_kind_of AudienceVoteService::Failure, result
    end

    # Retry should succeed because the transaction rolled back
    result = AudienceVoteService.new(
      user: @audience, game_prompt_id: @game_prompt.id,
      stars_params: stars, room: @room
    ).call

    assert_kind_of AudienceVoteService::Success, result
    assert_equal 3, Vote.where(user: @audience, game_prompt: @game_prompt).count
  end
end
