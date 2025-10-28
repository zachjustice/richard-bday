class AboutController < ApplicationController
  # Skip authentication for about page
  skip_before_action :require_authentication
  skip_before_action :redirect_bots_to_babble

  def show
    # Render the about page
  end
end
