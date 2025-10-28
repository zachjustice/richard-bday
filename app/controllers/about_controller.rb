class AboutController < ApplicationController
  # Skip authentication for about page
  skip_before_action :require_authentication

  def show
    # Render the about page
  end
end
