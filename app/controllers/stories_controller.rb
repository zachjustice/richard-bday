# app/controllers/stories_controller.rb
class StoriesController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth
  before_action :set_story, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_story_owner!, only: [ :edit, :update, :destroy ]

  def index
    @stories = Story.visible_to(current_editor).includes(:author, :genres).order(created_at: :desc)
  end

  def show
    @blanks = @story.blanks.index_by(&:id)
    @validation = @story.validate_blanks
  end

  def new
    @story = Story.new
    @genres = Genre.all.order(:name)
  end

  def create
    @story = Story.new(story_params)
    @story.author = current_editor

    if @story.save
      redirect_to story_path(@story)
    else
      @genres = Genre.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @blanks = @story.blanks.order(:id)
    @genres = Genre.all.order(:name)
  end

  def update
    @genres = Genre.all.order(:name)

    if @story.update(story_params)
      flash[:notice] = "Story updated successfully"
      respond_to do |format|
        format.html {
          redirect_to edit_story_path(@story), notice: "Story updated successfully"
        }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "story_form",
              partial: "stories/form",
              locals: { story: @story, success: true }
            ),
            turbo_stream.prepend("flash-messages", partial: "shared/flash_messages")
          ]
        end
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
    @story.destroy
    redirect_to stories_path, notice: "Story deleted successfully"
  end

  def prompts
    @prompts = Prompt.all.order(created_at: :desc)

    render json: @prompts.map { |p|
      {
        id: p.id,
        description: p.description,
        tags: p.tags,
        usage_count: p.story_prompts.select(:story_id).distinct.count
      }
    }
  end

  private

  def set_story
    @story = Story.find(params[:id])
  end

  def authorize_story_owner!
    unless @story.owned_by?(current_editor)
      redirect_to stories_path, alert: "You are not authorized to edit this story"
    end
  end

  def trim_params(permitted_params)
    permitted_params.each do |key, value|
      permitted_params[key] = value.strip if value.is_a?(String)
    end
    permitted_params
  end

  def story_params
    trim_params(
      params.require(:story).permit(:title, :original_text, :text, :published, genre_ids: [])
    )
  end
end
