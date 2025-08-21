class PromptsController < ApplicationController
  def show
    exists = Answer.exists?(
      prompt_id: params[:id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )

    # User already submitted an answer for this prompt; redirect to next page
    if exists
      redirect_to controller: "prompts", action: "waiting", id: params[:id]
    end

    @prompt = Prompt.find_by(params.permit(:id))
  end

  def waiting
    users_in_room = User.where(room_id: @current_room.id).count
    submitted_answers = Answer.where(prompt_id: params[:id], room_id: @current_room.id).count
    redirect_to_voting = submitted_answers >= users_in_room

    # All answers have been collected, time to vote
    if redirect_to_voting
      return redirect_to controller: "prompts", action: "voting", id: params[:id]
    end

    @prompt = Prompt.find_by(params.permit(:id))
    @users_with_submitted_answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id]).map { |r| r.user.name }
  end

  def voting
    exists = Vote.exists?(
      prompt_id: params[:id],
      user_id: @current_user.id,
      room_id: @current_room.id
    )

    # All answers have been collected, time to vote
    if exists
      return redirect_to controller: "prompts", action: "results", id: params[:id]
    end

    @prompt = Prompt.find_by(params.permit(:id))
    @answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id])
  end

  def results
    prompt_id = params[:id]
    @prompt = Prompt.find_by(params.permit(:id))
    @votes = Vote.where(room_id: @current_room.id, prompt_id: params[:id])
    answers = Answer.where(room_id: @current_room.id, prompt_id: params[:id])
    @answers_by_id = answers.reduce({}) { |result, curr|
      result[curr.id] = curr
      result
    }

    num_users_in_room = User.where(room_id: @current_room.id).count
    submitted_votes = Vote.where(prompt_id: prompt_id, room_id: @current_room.id)
    @votes_by_answer = {}
    most_votes = -1
    @winners = []

    # Only calculate winners if all the votes are in. Front-end will use existence of @winners to determine if voting is done.
    if num_users_in_room <= submitted_votes.size
      submitted_votes.each do |vote|
        if @votes_by_answer[vote.answer_id].nil?
          @votes_by_answer[vote.answer_id] = []
        end
        @votes_by_answer[vote.answer_id].push(vote)
        if @votes_by_answer[vote.answer_id].size > most_votes
          most_votes = @votes_by_answer[vote.answer_id].size
          @winners = [ @answers_by_id[vote.answer_id] ]
        elsif @votes_by_answer[vote.answer_id].size == most_votes
          @winners.push(@answers_by_id[vote.answer_id])
        end
      end
    end
  end
end
