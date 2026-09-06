# Quien puede administrar un producto del catalogo.
#
# Solo desde adentro del almacen que lo publica. A diferencia de
# OrganizationPolicy, aca `clerk` si manda: vender es exactamente su trabajo.
module ProductPolicy
  module_function

  MANAGING_ROLES = %w[owner admin clerk].freeze

  def manage?(product)
    membership = Current.membership

    return false if membership.nil?
    return false unless membership.organization_id == product.organization_id

    MANAGING_ROLES.include?(membership.role)
  end
end
