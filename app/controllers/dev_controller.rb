class DevController < ApplicationController
  allow_unauthenticated_access
  before_action :block_in_production
  layout false

  def decorations
  end

  private

  def block_in_production
    raise ActionController::RoutingError, "Not Found" if Rails.env.production?
  end
end
