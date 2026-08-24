# Autenticacion por token bearer.
#
# Todos los endpoints exigen sesion salvo los que se marquen explicitamente con
# `allow_unauthenticated_access`: es mas seguro que un endpoint nuevo quede
# protegido por olvido a que quede abierto por olvido.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def require_authentication
    @current_session = Session.authenticate(bearer_token)

    render json: { error: "unauthorized" }, status: :unauthorized if @current_session.nil?
  end

  def current_user
    @current_session&.user
  end

  def current_session
    @current_session
  end

  def bearer_token
    request.authorization.to_s[/\ABearer (.+)\z/, 1]
  end
end
