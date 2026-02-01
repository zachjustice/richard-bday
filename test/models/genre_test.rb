require "test_helper"

class GenreTest < ActiveSupport::TestCase
  test "genre requires name" do
    genre = Genre.new
    assert_not genre.valid?
    assert_includes genre.errors[:name], "can't be blank"
  end

  test "genre name must be unique" do
    existing = genres(:comedy)
    duplicate = Genre.new(name: existing.name)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "genre can have multiple stories" do
    genre = genres(:comedy)
    story1 = stories(:one)

    # story1 is already associated with comedy via fixtures
    assert_includes genre.stories, story1
  end

  test "destroying genre destroys story_genres but not stories" do
    genre = genres(:comedy)
    story = stories(:one)

    assert_includes genre.stories, story

    genre.destroy

    assert story.reload
    assert_equal 0, StoryGenre.where(genre_id: genre.id).count
  end
end
