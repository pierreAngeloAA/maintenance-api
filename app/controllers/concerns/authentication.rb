# Autenticacion por token bearer y resolucion del actor activo.
#
# Todos los endpoints exigen sesion salvo los que se marquen explicitamente con
# `allow_unauthenticated_access`: es mas seguro que un endpoint nuevo quede
# protegido por olvido a que quede abierto por olvido.
#
# El token dice *quien eres*. El header X-Organization-Id dice *en nombre de
# quien actuas*, y nunca se le cree solo: se valida contra las membresias en
# cada peticion.
module Authentication
  extend ActiveSupport::Concern

  ORGANIZATION_HEADER = "X-Organization-Id".freeze

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

    return render json: { error: "unauthorized" }, status: :unauthorized if @current_session.nil?

    Current.session = @current_session
    Current.user = @current_session.user

    resolve_organization
  end

  # Sin header, la persona actua como cliente sobre sus propios vehiculos.
  def resolve_organization
    requested = request.headers[ORGANIZATION_HEADER]
    return if requested.blank?

    membership = current_user.memberships.accepted.find_by(organization_id: requested)

    return render json: { error: "forbidden" }, status: :forbidden if membership.nil?
    return render json: { error: "forbidden" }, status: :forbidden if membership.organization.suspended?

    Current.membership = membership
    Current.organization = membership.organization
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
