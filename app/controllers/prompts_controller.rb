class PromptsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_editor_auth
  before_action :set_prompt, only: [ :edit_prompt, :update_prompt, :destroy_prompt ]
  before_action :authorize_prompt_owner!, only: [ :edit_prompt, :update_prompt, :destroy_prompt ]

  def index
    @prompts = Prompt.includes(:creator).order(created_at: :desc)

    if params[:query].present?
      query = "%#{params[:query]}%"
      @prompts = @prompts.left_joins(:creator)
                         .where("prompts.description LIKE :q OR editors.username LIKE :q", q: query)
                         .distinct
    end

    respond_to do |format|
      format.html
      format.turbo_stream { render partial: "prompts/prompts_list", locals: { prompts: @prompts } }
    end
  end

  def new
    @prompt = Prompt.new
  end

  def create_prompt
    @prompt = Prompt.new(prompt_params)
    @prompt.creator = current_editor

    if @prompt.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "prompts_list",
              partial: "prompts/prompt",
              locals: { prompt: @prompt }
            ),
            turbo_stream.replace(
              "new_prompt_form",
              partial: "prompts/form",
              locals: { prompt: Prompt.new }
            )
          ]
        end
        format.html { redirect_to prompts_index_path, notice: "Prompt created successfully" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_prompt_form",
            partial: "prompts/form",
            locals: { prompt: @prompt }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit_prompt
  end

  def update_prompt
    return if performed?

    if @prompt.update(prompt_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "prompt_#{@prompt.id}",
            partial: "prompts/prompt",
            locals: { prompt: @prompt }
          )
        end
        format.html { redirect_to prompts_index_path, notice: "Prompt updated successfully" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "prompt_#{@prompt.id}",
            partial: "prompts/prompt_form",
            locals: { prompt: @prompt }
          )
        end
        format.html { render :edit_prompt, status: :unprocessable_entity }
      end
    end
  end

  def destroy_prompt
    return if performed?

    @prompt.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("prompt_#{@prompt.id}")
      end
      format.html { redirect_to prompts_index_path, notice: "Prompt deleted successfully" }
    end
  end

  private

  def set_prompt
    @prompt = Prompt.find(params[:id])
  end

  def authorize_prompt_owner!
    return if @prompt.owned_by?(current_editor)

    respond_to do |format|
      format.turbo_stream { head :forbidden }
      format.html { redirect_to prompts_index_path, alert: "You are not authorized to edit this prompt" }
    end
  end

  def trim_params(permitted_params)
    permitted_params.each do |key, value|
      permitted_params[key] = value.strip if value.is_a?(String)
    end
    permitted_params
  end

  def prompt_params
    trim_params(params.require(:prompt).permit(:description, :tags))
  end
end
