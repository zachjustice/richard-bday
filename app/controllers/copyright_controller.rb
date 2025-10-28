class CopyrightController < ApplicationController
  # Skip authentication for copyright page
  skip_before_action :require_authentication
  skip_before_action :redirect_bots_to_babble

  def show
    # Render the copyright page
  end
end
