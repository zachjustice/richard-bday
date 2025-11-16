class PromptsController < ApplicationController
  before_action :redirect_to_current_game_phase, except: [ :index, :new, :create_prompt, :edit_prompt, :update_prompt, :destroy_prompt, :tooltip ]

  def show
    exists = Answer.exists?(
      game_prompt_id: params[:id],
      user_id: @current_user.id,
      game: @current_room.current_game
    )

    # User already submitted an answer for this prompt; redirect to next page
    if exists
      return redirect_to controller: "prompts", action: "waiting", id: params[:id]
    end

    @game_prompt = GamePrompt.find_by(params.permit(:id))
  end

  def waiting
    @game_prompt = GamePrompt.find_by(params.permit(:id))

    # All answers have been collected, time to vote
    if @current_room.status == RoomStatus::Voting
      redirect_to controller: "prompts", action: "voting", id: params[:id]
    end
  end

  def voting
    exists = Vote.exists?(
      user_id: @current_user.id,
      game_prompt_id: params[:id]
    )

    # All answers have been collected, time to vote
    if exists
      return redirect_to controller: "prompts", action: "results", id: params[:id]
    end
    @game_prompt = GamePrompt.find_by(params.permit(:id))
    @answers = Answer.where(game_id: @current_room.current_game_id, game_prompt_id: params[:id]).reject do |ans|
      ans.user_id == @current_user.id
    end
  end

  def results
    @status = @current_room.status
  end

  def tooltip
    @game_prompt = GamePrompt.find(params[:id])
    @answers = Answer.where(game_prompt_id: @game_prompt.id)
    @votes = Vote.where(game_prompt_id: @game_prompt.id)

    @votes_by_answer = @votes.group_by(&:answer_id)

    render partial: "prompts/tooltip_content",
          locals: {
            game_prompt: @game_prompt,
            answers: @answers,
            votes_by_answer: @votes_by_answer
          },
          layout: false
  end

  def index
    @prompts = Prompt.all.order(created_at: :desc)
  end

  def new
    @prompt = Prompt.new
  end

  def create_prompt
    @prompt = Prompt.new(prompt_params)

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
        format.html { redirect_to prompts_path, notice: "Prompt created successfully" }
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
    @prompt = Prompt.find(params[:id])
  end

  def update_prompt
    @prompt = Prompt.find(params[:id])

    if @prompt.update(prompt_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "prompt_#{@prompt.id}",
            partial: "prompts/prompt",
            locals: { prompt: @prompt }
          )
        end
        format.html { redirect_to prompts_path, notice: "Prompt updated successfully" }
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
    @prompt = Prompt.find(params[:id])
    @prompt.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("prompt_#{@prompt.id}")
      end
      format.html { redirect_to prompts_path, notice: "Prompt deleted successfully" }
    end
  end

  private

  def prompt_params
    params.require(:prompt).permit(:description, :tags)
  end

  def redirect_to_current_game_phase
    controller = params[:controller]
    action = params[:action]
    id = params[:id].to_i
    current_game_prompt_id = @current_room.current_game&.current_game_prompt&.id
    case @current_room.status
    when RoomStatus::WaitingRoom
      if controller != "rooms" || id != @current_room.id || [ "show", "waiting_for_new_game" ].include?(action)
        redirect_to controller: "rooms", action: "waiting_for_new_game", id: @current_room.id
      end
    when RoomStatus::Answering
      if controller != "prompts" || id != current_game_prompt_id || ![ "show", "waiting" ].include?(action)
        redirect_to controller: "prompts", action: "show", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::Voting
      if controller != "prompts" || id != current_game_prompt_id || ![ "voting", "results" ].include?(action)
        redirect_to controller: "prompts", action: "voting", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::Results
      if controller != "prompts" || id != current_game_prompt_id || action != "results"
        redirect_to controller: "prompts", action: "results", id: @current_room.current_game.current_game_prompt.id
      end
    when RoomStatus::FinalResults
      if controller != "prompts" || id != current_game_prompt_id || action != "results"
        redirect_to controller: "prompts", action: "results", id: @current_room.current_game.current_game_prompt.id
      end
    else
      redirect_to controller: "rooms", action: "show"
    end
  end
end
