class PromptsController < ApplicationController
  def show
    @prompt = Prompt.find_by(params.permit(:id))
  end
end
