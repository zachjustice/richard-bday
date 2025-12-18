# app/controllers/blanks_controller.rb
class BlanksController < ApplicationController
  allow_unauthenticated_access only: %i[ create update destroy ]

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
            turbo_stream.action(:close_modal, "blank-modal"),
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

  def update
    @story = Story.find(params[:story_id])
    @blank = @story.blanks.find(params[:id])

    if @blank.update(blank_params)
      flash[:notice] = "Successfully updated Blank"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "blank_#{@blank.id}",
              partial: "blanks/blank",
              locals: { blank: @blank, story: @story }
            ),
            turbo_stream.replace("flash-messages", partial: "shared/flash_messages")
          ]
        end
        format.html { redirect_to edit_story_path(@story) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "blank_#{@blank.id}",
            partial: "blanks/blank_form",
            locals: { blank: @blank, story: @story }
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
