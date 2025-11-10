# app/controllers/blanks_controller.rb
class BlanksController < ApplicationController
  allow_unauthenticated_access only: %i[ create update destroy ]

  def create
    @story = Story.find(params[:story_id])
    @blank = @story.blanks.build(blank_params)

    if @blank.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "blanks_list",
              partial: "blanks/blank",
              locals: { blank: @blank, story: @story }
            ),
            turbo_stream.replace(
              "new_blank_form",
              partial: "blanks/form",
              locals: { story: @story, blank: Blank.new }
            )
          ]
        end
        format.html { redirect_to edit_story_path(@story) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_blank_form",
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
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "blank_#{@blank.id}",
            partial: "blanks/blank",
            locals: { blank: @blank, story: @story }
          )
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
end
