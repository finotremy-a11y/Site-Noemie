class HomeController < ApplicationController
  DEFAULT_HERO_BURGER_IMAGE = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1800&q=80".freeze

  def index
    @hero_media_url = ENV["HERO_MEDIA_URL"].presence || DEFAULT_HERO_BURGER_IMAGE
    @hero_media_mode = ENV.fetch("HERO_MEDIA_MODE", "fixed")
  end
end
