class ApplicationController < ActionController::Base
  include Authentication

  if Rails.env.production?
    allow_browser versions: { safari: 16.4, chrome: 111, firefox: 128 }
  end

  stale_when_importmap_changes

  add_flash_types :celebrate
end
