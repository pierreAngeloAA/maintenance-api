class ApplicationController < ActionController::API
  include CamelCasePayload
  include Authentication
  include Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  # Codigo estable en vez de texto: el mensaje que ve el usuario lo pone el
  # frontend, que es donde vive el espanol.
  def render_not_found
    render json: { error: "not_found" }, status: :not_found
  end
end
