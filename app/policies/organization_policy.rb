# Quien puede administrar una organizacion.
#
# Solo desde adentro: hay que estar actuando en nombre de esa organizacion
# (header X-Organization-Id) y con un rol que mande. Un `clerk` de un almacen
# vende, pero no le cambia el nombre ni el NIT al negocio.
module OrganizationPolicy
  module_function

  MANAGING_ROLES = %w[owner admin].freeze

  def manage?(organization)
    membership = Current.membership

    return false if membership.nil?
    return false unless membership.organization_id == organization.id

    MANAGING_ROLES.include?(membership.role)
  end
end
