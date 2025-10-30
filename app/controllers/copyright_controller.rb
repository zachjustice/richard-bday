class CopyrightController < ApplicationController
  # Skip authentication for copyright page
  skip_before_action :require_authentication

  def show
    # Render the copyright page
  end
end
