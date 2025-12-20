# frozen_string_literal: true

require "ostruct"

class StoryBlanksUpdateService
  attr_reader :story, :blank, :tags, :existing_prompt_ids, :new_prompts, :errors

  def initialize(story:, blank:, params:)
    @story = story
    @blank = blank
    @tags = params[:tags]
    @existing_prompt_ids = Array(params[:existing_prompt_ids]).reject(&:blank?).map(&:to_i)
    @new_prompts = Array(params[:new_prompts]).reject { |p| p[:description].blank? }
    @errors = []
  end

  def call
    validate_inputs
    return failure_result if @errors.any?

    ActiveRecord::Base.transaction do
      update_blank_tags
      new_prompt_records = create_new_prompts
      all_prompt_ids = @existing_prompt_ids + new_prompt_records.map(&:id)
      sync_story_prompts(all_prompt_ids)
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

  def update_blank_tags
    @blank.update!(tags: @tags)
  end

  def create_new_prompts
    @new_prompts.map do |prompt_data|
      prompt = Prompt.new(
        description: prompt_data[:description],
        tags: @tags
      )
      prompt.save!
      prompt
    end
  end

  def sync_story_prompts(new_prompt_ids)
    current_prompt_ids = @blank.story_prompts.where(story: @story).pluck(:prompt_id)

    # Remove prompts that are no longer selected
    prompts_to_remove = current_prompt_ids - new_prompt_ids
    if prompts_to_remove.any?
      StoryPrompt.where(
        story: @story,
        blank: @blank,
        prompt_id: prompts_to_remove
      ).destroy_all
    end

    # Add new prompts that weren't previously associated
    prompts_to_add = new_prompt_ids - current_prompt_ids
    prompts_to_add.each do |prompt_id|
      StoryPrompt.create!(
        story: @story,
        blank: @blank,
        prompt_id: prompt_id
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
