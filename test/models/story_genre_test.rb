require "test_helper"

class StoryGenreTest < ActiveSupport::TestCase
  test "story_genre requires story" do
    story_genre = StoryGenre.new(genre: genres(:comedy))
    assert_not story_genre.valid?
  end

  test "story_genre requires genre" do
    story_genre = StoryGenre.new(story: stories(:one))
    assert_not story_genre.valid?
  end

  test "story_genre prevents duplicate story-genre pairs" do
    existing = story_genres(:one_comedy)
    duplicate = StoryGenre.new(story: existing.story, genre: existing.genre)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:genre_id], "has already been taken"
  end

  test "same genre can be used on different stories" do
    genre = genres(:comedy)
    story2 = stories(:two)

    story_genre = StoryGenre.new(story: story2, genre: genre)
    assert story_genre.valid?
  end
end
