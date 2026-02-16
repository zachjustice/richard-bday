# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "ostruct"

class AnswerSmoothingServiceTest < ActiveSupport::TestCase
  def setup
    # Create isolated test data to avoid fixture conflicts
    suffix = SecureRandom.hex(4)
    @room = Room.create!(code: "smooth#{suffix}", status: RoomStatus::WaitingRoom, smooth_answers: true)
    @story = Story.create!(title: "SmoothTest Story #{suffix}", text: "The {BLANK} went to the store.", original_text: "Test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @editor = Editor.create!(username: "sm#{suffix}", email: "sm#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "What do you do when hurt?", tags: "action", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @user = User.create!(name: "Smth#{suffix[0..5]}", room: @room, role: User::PLAYER)

    # Update story text with actual blank id
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    @answer = Answer.create!(
      game_prompt: @game_prompt,
      game: @game,
      user: @user,
      text: "I go to the doctor"
    )
  end

  test "returns original text when smoothing disabled" do
    @room.update!(smooth_answers: false)

    service = AnswerSmoothingService.new(@answer)
    result = service.call

    assert_equal @answer.text, result
  end

  test "extracts context correctly from story" do
    # Story text is "The {1} went to the {2}."
    # Blank three has id that creates placeholder {<id>}
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    service = AnswerSmoothingService.new(@answer)
    context = service.send(:extract_context)

    assert_equal "The", context[:before]
    assert_equal "went to the store.", context[:after]
  end

  test "handles placeholder at start of story" do
    @story.update!(text: "{#{@blank.id}} is a great place to visit.")

    service = AnswerSmoothingService.new(@answer)
    context = service.send(:extract_context)

    assert_equal "", context[:before]
    assert_includes context[:after], "is a great place"
  end

  test "handles placeholder at end of story" do
    @story.update!(text: "I really love {#{@blank.id}}")

    service = AnswerSmoothingService.new(@answer)
    context = service.send(:extract_context)

    assert_includes context[:before], "I really love"
    assert_equal "", context[:after]
  end

  test "returns original text when placeholder not found" do
    @story.update!(text: "No placeholder here")

    service = AnswerSmoothingService.new(@answer)
    context = service.send(:extract_context)

    assert_equal "", context[:before]
    assert_equal "", context[:after]
  end

  test "includes adjacent sentences when current sentence is very short" do
    # Sentence with only 1 word (< MIN_SENTENCE_WORDS=2) should include neighbors
    @story.update!(text: "This is the beginning. {#{@blank.id}}! This is the end.")

    service = AnswerSmoothingService.new(@answer)
    context = service.send(:extract_context)

    assert_includes context[:before], "This is the beginning."
    assert_includes context[:after], "This is the end."
  end

  test "uses only current sentence when it has enough words" do
    # Sentence with 2+ words should only include the current sentence
    @story.update!(text: "Before sentence here. I {#{@blank.id}} daily. After sentence here.")

    service = AnswerSmoothingService.new(@answer)
    context = service.send(:extract_context)

    assert_equal "I", context[:before]
    assert_equal "daily.", context[:after]
    refute_includes context[:before], "Before"
    refute_includes context[:after], "After"
  end

  test "returns original text on API error" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    # Stub the client to raise an error
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { raise StandardError, "API Error" }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal @answer.text, result
    end
  end

  test "returns smoothed text on success" do
    @story.update!(text: "I got stabbed so I {#{@blank.id}}.")

    # Use OpenStruct for simpler mocking - response now includes XML tags
    mock_text = OpenStruct.new(text: "<answer>went to the doctor</answer>")
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal "went to the doctor", result
    end
  end

  test "returns original text when API returns empty response" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    mock_text = OpenStruct.new(text: "<answer></answer>")
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal @answer.text, result
    end
  end

  test "returns original text when response has no answer tags" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    mock_text = OpenStruct.new(text: "some random text without tags")
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal @answer.text, result
    end
  end

  test "handles whitespace-only content in answer tags" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    mock_text = OpenStruct.new(text: "<answer>   </answer>")
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal @answer.text, result
    end
  end

  test "handles multiline content in answer tags" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    mock_text = OpenStruct.new(text: "<answer>\nmultiline\nanswer\n</answer>")
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal "multiline\nanswer", result
    end
  end

  test "returns original text when LLM echoes entire sentence" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    # The service builds sentence as "#{context[:before]} [[#{@answer.text}]] #{context[:after]}"
    # which becomes "The [[I go to the doctor]] went to the store."
    echoed_sentence = "The #{@answer.text} went to the store."
    mock_text = OpenStruct.new(text: echoed_sentence)
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal @answer.text, result
    end
  end

  test "returns original text when LLM response is too long" do
    @story.update!(text: "The {#{@blank.id}} went to the store.")

    # Response longer than 2x the original answer length should be rejected
    # Original: "I go to the doctor" (19 chars), so >= 38 chars should fail
    long_response = "a" * (@answer.text.length * 2)
    mock_text = OpenStruct.new(text: long_response)
    mock_response = OpenStruct.new(content: [ mock_text ])
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_kwargs| mock_response }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }

    AnswerSmoothingService.stub_any_instance(:anthropic_client, mock_client) do
      service = AnswerSmoothingService.new(@answer)
      result = service.call

      assert_equal @answer.text, result
    end
  end
end
