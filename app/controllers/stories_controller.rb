# app/controllers/stories_controller.rb
class StoriesController < ApplicationController
  before_action :is_editor

  def index
    @stories = Story.all.order(created_at: :desc)
  end

  def show
    @story = Story.find(params[:id])
    @blanks = @story.blanks.index_by(&:id)
    @validation = @story.validate_blanks
  end

  def new
    @story = Story.new
  end

  def create
    @story = Story.new(story_params)

    if @story.save
      redirect_to story_path(@story), notice: "Story created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @story = Story.find(params[:id])
    @blanks = @story.blanks.order(:id)
  end

  def update
    @story = Story.find(params[:id])

    if @story.update(story_params)
      respond_to do |format|
        format.html { redirect_to story_path(@story), notice: "Story updated successfully" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "story_form",
            partial: "stories/form",
            locals: { story: @story }
          )
        end
      end
    end
  end

  def destroy
    @story = Story.find(params[:id])
    @story.destroy
    redirect_to stories_path, notice: "Story deleted successfully"
  end

  private

  def is_editor
    if !@current_user.editor?
      redirect_to root_path
    end
  end

  def story_params
    params.require(:story).permit(:title, :original_text, :text)
  end
end
