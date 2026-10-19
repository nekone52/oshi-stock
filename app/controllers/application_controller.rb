class ApplicationController < ActionController::Base
  include Authentication

  if Rails.env.production?
    allow_browser versions: { safari: 16.4, chrome: 111, firefox: 128 }
  end

  stale_when_importmap_changes

  add_flash_types :celebrate

  private

  def find_selected_character
    return if params[:character_id].blank?

    Current.user.characters.find_by(id: params[:character_id])
  end
end
