require "wahwah"
class MusicPlayerController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  @songs = nil

  def index
    # Return all available songs as JSON
    @songs = @songs || load_songs
    respond_to do |format|
      format.json { render json: @songs }
      format.html { head :not_found }
    end
  end

  private

  def load_songs
    Dir.glob("app/assets/audios/*.mp3").map.with_index do |filename, index|
      metadata = WahWah.open(filename)
      {
        id: index,
        title: metadata.title,
        artist: metadata.artist,
        duration: metadata.duration,
        file: ActionController::Base.helpers.asset_path(filename.split("/").last),
        credit_url: metadata.comments.first
      }
    end
  end
end
