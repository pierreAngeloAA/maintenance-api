# Autorizacion: la otra mitad de la pregunta.
#
# `Authentication` responde "hay sesion?". Esto responde "puede este actor hacer
# esto sobre este registro?". La respuesta la dan las politicas de
# `app/policies/`, que leen de `Current` y no de los parametros.
#
# Denegado por defecto: una accion que nunca llama a `authorize` revienta la
# suite. Igual que en `Authentication`, es mas seguro que un endpoint nuevo
# quede protegido por olvido a que quede abierto por olvido. Fuera de produccion
# se levanta la excepcion para que el descuido se vea en los tests; en
# produccion no se levanta porque la respuesta ya se rendero y volver a
# renderizar seria un error doble.
module Authorization
  extend ActiveSupport::Concern

  class PolicyNotChecked < StandardError; end

  included do
    after_action :verify_policy_checked
  end

  class_methods do
    # Para acciones que de verdad no autorizan nada: registro, login, catalogos
    # publicos. Explicito, para que la excepcion sea una decision y no un olvido.
    def skip_authorization(**options)
      skip_after_action :verify_policy_checked, **options
    end
  end

  private

  def authorize(permitted)
    @policy_checked = true

    return if permitted

    render json: { error: "forbidden" }, status: :forbidden
  end

  def verify_policy_checked
    return if @policy_checked
    return if Rails.env.production?

    raise PolicyNotChecked,
      "#{controller_name}##{action_name} no llamo a authorize: toda accion declara su politica"
  end
end
