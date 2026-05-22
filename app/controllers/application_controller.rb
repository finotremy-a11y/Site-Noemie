class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :user_signed_in?

  before_action :set_current_user

  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def set_current_user
    if session[:session_token]
      @current_user = User.find_by(api_token: session[:session_token])
    end
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      session[:return_to] = request.url
      redirect_to login_path, alert: "Vous devez d'abord vous connecter"
    end
  end

  def not_found
    render file: "public/404.html", status: :not_found, layout: false
  end
end
