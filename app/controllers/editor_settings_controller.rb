class EditorSettingsController < ApplicationController
  include EditorSettingsRenderable
  skip_before_action :require_authentication
  before_action :require_editor_auth

  def show
    set_settings_view_data
    if params[:query].present?
      @statistics = @statistics.select { |s| s[:story].title.match?(/#{Regexp.escape(params[:query])}/i) }
    end
  end
end
