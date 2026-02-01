require "test_helper"

class StoryTest < ActiveSupport::TestCase
  setup do
    @editor_one = editors(:one)
    @editor_two = editors(:two)
    @published_story = stories(:one)      # published, owned by editor_one
    @unpublished_story = stories(:two)    # unpublished, owned by editor_two
    @public_no_author = stories(:three)   # published, no author
  end

  # owned_by? tests
  test "owned_by? returns true for story author" do
    assert @published_story.owned_by?(@editor_one)
  end

  test "owned_by? returns false for non-author" do
    assert_not @published_story.owned_by?(@editor_two)
  end

  test "owned_by? returns false for nil editor" do
    assert_not @published_story.owned_by?(nil)
  end

  test "owned_by? returns false for story with no author" do
    assert_not @public_no_author.owned_by?(@editor_one)
  end

  # visible_to scope tests
  test "visible_to returns published stories for nil editor" do
    visible = Story.visible_to(nil)

    assert_includes visible, @published_story
    assert_includes visible, @public_no_author
    assert_not_includes visible, @unpublished_story
  end

  test "visible_to returns published stories plus own unpublished for editor" do
    visible = Story.visible_to(@editor_two)

    # Editor two can see all published stories
    assert_includes visible, @published_story
    assert_includes visible, @public_no_author
    # Editor two can see their own unpublished story
    assert_includes visible, @unpublished_story
  end

  test "visible_to excludes other editors unpublished stories" do
    visible = Story.visible_to(@editor_one)

    # Editor one cannot see editor two's unpublished story
    assert_not_includes visible, @unpublished_story
  end

  # published scope tests
  test "published scope returns only published stories" do
    published = Story.published

    assert_includes published, @published_story
    assert_includes published, @public_no_author
    assert_not_includes published, @unpublished_story
  end

  # owned_by scope tests
  test "owned_by scope returns stories by specific editor" do
    owned = Story.owned_by(@editor_one)

    assert_includes owned, @published_story
    assert_not_includes owned, @unpublished_story
    assert_not_includes owned, @public_no_author
  end

  # Genre association tests
  test "story can have multiple genres" do
    genre1 = genres(:comedy)
    genre2 = genres(:horror)

    story = Story.create!(
      title: "Multi-genre Story",
      original_text: "A scary comedy",
      text: "A scary comedy",
      author: @editor_one
    )
    story.genres << genre1
    story.genres << genre2

    assert_equal 2, story.genres.count
    assert_includes story.genres, genre1
    assert_includes story.genres, genre2
  end
end
