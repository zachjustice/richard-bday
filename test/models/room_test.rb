require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "Create Room" do
    r = Room.new(code: "asdf")
    assert r.save
  end

  # --- Scoring / Config ---

  test "points_for_rank returns 1 for vote_once regardless of rank" do
    room = Room.new(code: "vo", voting_style: "vote_once")
    assert_equal 1, room.points_for_rank(1)
    assert_equal 1, room.points_for_rank(2)
    assert_equal 1, room.points_for_rank(99)
  end

  test "points_for_rank returns ranked points for ranked_top_3" do
    room = Room.new(code: "rk", voting_style: "ranked_top_3")
    assert_equal 30, room.points_for_rank(1)
    assert_equal 20, room.points_for_rank(2)
    assert_equal 10, room.points_for_rank(3)
  end

  test "points_for_rank returns 0 for out-of-range rank in ranked_top_3" do
    room = Room.new(code: "rk", voting_style: "ranked_top_3")
    assert_equal 0, room.points_for_rank(4)
    assert_equal 0, room.points_for_rank(100)
  end

  test "points_for_rank returns 1 when rank is nil" do
    vote_once = Room.new(code: "vo", voting_style: "vote_once")
    ranked = Room.new(code: "rk", voting_style: "ranked_top_3")
    assert_equal 1, vote_once.points_for_rank(nil)
    assert_equal 1, ranked.points_for_rank(nil)
  end

  test "max_ranks returns 3 for ranked_top_3" do
    room = Room.new(code: "rk", voting_style: "ranked_top_3")
    assert_equal 3, room.max_ranks
  end

  test "max_ranks returns 1 for vote_once" do
    room = Room.new(code: "vo", voting_style: "vote_once")
    assert_equal 1, room.max_ranks
  end

  test "voting_config returns correct defaults for each style" do
    vote_once = Room.new(code: "vo", voting_style: "vote_once")
    ranked = Room.new(code: "rk", voting_style: "ranked_top_3")

    assert_equal Room::VOTING_STYLE_DEFAULTS["vote_once"], vote_once.voting_config
    assert_equal Room::VOTING_STYLE_DEFAULTS["ranked_top_3"], ranked.voting_config
  end

  test "ranked_voting? and vote_once? return correct booleans" do
    vote_once = Room.new(code: "vo", voting_style: "vote_once")
    ranked = Room.new(code: "rk", voting_style: "ranked_top_3")

    assert vote_once.vote_once?
    assert_not vote_once.ranked_voting?
    assert ranked.ranked_voting?
    assert_not ranked.vote_once?
  end

  # --- Code Generation ---

  test "generate_unique_code returns a 4-character lowercase code" do
    code = Room.generate_unique_code
    assert_equal 4, code.length
    assert_match(/\A[a-z]+\z/, code)
  end

  test "generate_unique_code retries on collision and succeeds" do
    call_count = 0
    original_exists = Room.method(:exists?)
    Room.define_singleton_method(:exists?) do |*args, **kwargs|
      call_count += 1
      call_count < 3
    end

    code = Room.generate_unique_code
    assert_equal 4, code.length
    assert_equal 3, call_count
  ensure
    Room.define_singleton_method(:exists?, original_exists)
  end

  test "generate_unique_code raises after max_retries exhausted" do
    original_exists = Room.method(:exists?)
    Room.define_singleton_method(:exists?) { |*args, **kwargs| true }

    error = assert_raises(RuntimeError) { Room.generate_unique_code(max_retries: 3) }
    assert_match(/Failed to generate/, error.message)
  ensure
    Room.define_singleton_method(:exists?, original_exists)
  end

  # --- Validation Boundaries ---

  test "time_to_answer_seconds accepts minimum boundary value" do
    room = Room.new(code: "t1", time_to_answer_seconds: 30)
    assert room.valid?
  end

  test "time_to_answer_seconds rejects below minimum" do
    room = Room.new(code: "t2", time_to_answer_seconds: 29)
    assert_not room.valid?
    assert room.errors[:time_to_answer_seconds].any?
  end

  test "time_to_answer_seconds accepts maximum boundary value" do
    room = Room.new(code: "t3", time_to_answer_seconds: 1200)
    assert room.valid?
  end

  test "time_to_answer_seconds rejects above maximum" do
    room = Room.new(code: "t4", time_to_answer_seconds: 1201)
    assert_not room.valid?
    assert room.errors[:time_to_answer_seconds].any?
  end

  test "voting_style rejects invalid value" do
    room = Room.new(code: "vs", voting_style: "invalid_style")
    assert_not room.valid?
    assert room.errors[:voting_style].any?
  end

  test "code presence is required" do
    room = Room.new(code: nil)
    assert_not room.valid?
    assert room.errors[:code].any?
  end
end
