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
      flash[:notice] = "Story updated successfully"
      # Turbo::StreamsChannel.broadcast_action_to(
      #   "rooms:#{@room.id}:status",
      #   action: :prepend,
      #   target: "body",
      #   partial: "shared/flash_messages"
      # )
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
    @story = Story.find(params[:id])
    @story.destroy
    redirect_to stories_path, notice: "Story deleted successfully"
  end

  def prompts
    @prompts = Prompt.all.order(created_at: :desc)

    render json: @prompts.map { |p|
      {
        id: p.id,
        description: p.description,
        tags: p.tags
      }
    }
  end

  private
  def trim_params(permitted_params)
    permitted_params.each do |key, value|
      permitted_params[key] = value.strip if value.is_a?(String)
    end
    permitted_params
  end

  def is_editor
    if !@current_user.editor?
      redirect_to root_path
    end
  end

  def story_params
    trim_params(
      params.require(:story).permit(:title, :original_text, :text)
    )
  end
end
