# frozen_string_literal: true

require "ostruct"

class StoryBlanksService
  attr_reader :story, :tags, :existing_prompt_ids, :new_prompts, :errors

  def initialize(story:, params:, creator:)
    @story = story
    @creator = creator
    @tags = params[:tags].split(",").map(&:strip).join(",")
    @existing_prompt_ids = Array(params[:existing_prompt_ids]).map(&:strip).reject(&:blank?)
    @new_prompts = Array(params[:new_prompts]).each { |p| p[:description].strip! }.reject { |p| p[:description].blank? }
    @errors = []
    @blank = nil
  end

  def call
    validate_inputs
    return failure_result if @errors.any?

    ActiveRecord::Base.transaction do
      @blank = create_blank
      new_prompt_records = create_new_prompts
      existing_prompts = find_existing_prompts
      all_prompts = existing_prompts + new_prompt_records
      create_story_prompts(@blank, all_prompts)
    end

    success_result
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    failure_result
  rescue StandardError => e
    @errors = [ e.message ]
    failure_result
  end

  private

  def validate_inputs
    @errors << "Tags can't be blank" if @tags.blank?

    if @existing_prompt_ids.empty? && @new_prompts.empty?
      @errors << "Must select at least one existing prompt or create a new one"
    end

    @new_prompts.each_with_index do |prompt_data, index|
      if prompt_data[:description].blank?
        @errors << "New prompt #{index + 1} description can't be blank"
      end
    end
  end

  def create_blank
    blank = @story.blanks.build(tags: @tags)
    blank.save!
    blank
  end

  def create_new_prompts
    @new_prompts.map do |prompt_data|
      prompt = Prompt.new(
        description: prompt_data[:description],
        tags: @tags,
        creator: @creator
      )
      prompt.save!
      prompt
    end
  end

  def find_existing_prompts
    return [] if @existing_prompt_ids.empty?

    Prompt.where(id: @existing_prompt_ids)
  end

  def create_story_prompts(blank, prompts)
    prompts.each do |prompt|
      StoryPrompt.create!(
        story: @story,
        blank: blank,
        prompt: prompt
      )
    end
  end

  def success_result
    OpenStruct.new(
      success: true,
      blank: @blank,
      errors: []
    )
  end

  def failure_result
    OpenStruct.new(
      success: false,
      blank: @blank,
      errors: @errors
    )
  end
end
