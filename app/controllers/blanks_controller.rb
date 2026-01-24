# app/controllers/blanks_controller.rb
class BlanksController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth

  def create
    @story = Story.find(params[:story_id])

    result = StoryBlanksService.new(
      story: @story,
      params: blank_with_prompts_params
    ).call

    if result.success
      @blank = result.blank
      flash[:notice] = "Successfully created Blank"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "blanks_list",
              partial: "blanks/blank",
              locals: { blank: @blank, story: @story }
            ),
            turbo_stream.replace(
              "blank-modal-form",
              partial: "blanks/form",
              locals: { story: @story, blank: Blank.new }
            ),
            turbo_stream.action(:close_modal, "blank-editor-modal"),
            turbo_stream.replace("flash-messages", partial: "shared/flash_messages")
          ]
        end
        format.html { redirect_to edit_story_path(@story) }
      end
    else
      @blank = @story.blanks.build(tags: blank_with_prompts_params[:tags])
      result.errors.each { |error| @blank.errors.add(:base, error) }

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "blank-modal-form",
            partial: "blanks/form",
            locals: { story: @story, blank: @blank }
          )
        end
        format.html { render "stories/edit", status: :unprocessable_entity }
      end
    end
  end

  # Gets data required for the Edit modal
  def edit
    @story = Story.find(params[:story_id])
    @blank = @story.blanks.find(params[:id])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "blank-modal-form",
            partial: "blanks/form",
            locals: { story: @story, blank: @blank }
          ),
          turbo_stream.update(
            "blank-modal-title",
            "Edit Blank #{@blank.id}"
          ),
          turbo_stream.action(:open_modal, "blank-editor-modal")
        ]
      end
    end
  end

  # Updates a Blank
  def update
    @story = Story.find(params[:story_id])
    @blank = @story.blanks.find(params[:id])

    result = StoryBlanksUpdateService.new(
      story: @story,
      blank: @blank,
      params: blank_with_prompts_params
    ).call

    if result.success
      flash[:notice] = "Successfully updated Blank"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "blank_#{@blank.id}",
              partial: "blanks/blank",
              locals: { blank: @blank, story: @story }
            ),
            turbo_stream.replace(
              "blank-modal-form",
              partial: "blanks/form",
              locals: { story: @story, blank: Blank.new }
            ),
            turbo_stream.action(:close_modal, "blank-editor-modal"),
            turbo_stream.replace("flash-messages", partial: "shared/flash_messages")
          ]
        end
        format.html { redirect_to edit_story_path(@story) }
      end
    else
      result.errors.each { |error| @blank.errors.add(:base, error) }
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "blank-modal-form",
            partial: "blanks/form",
            locals: { story: @story, blank: @blank }
          )
        end
        format.html { render "stories/edit", status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @story = Story.find(params[:story_id])
    @blank = @story.blanks.find(params[:id])
    @blank.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("blank_#{@blank.id}")
      end
      format.html { redirect_to edit_story_path(@story) }
    end
  end

  private

  def blank_params
    params.require(:blank).permit(:tags)
  end

  def blank_with_prompts_params
    params.require(:blank).permit(
      :tags,
      existing_prompt_ids: [],
      new_prompts: [ :description ]
    )
  end
end
