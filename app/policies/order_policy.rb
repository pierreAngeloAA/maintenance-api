# Quien puede despachar una venta del almacen.
#
# Igual que con el catalogo, `clerk` si manda: despachar es su trabajo.
module OrderPolicy
  module_function

  FULFILLING_ROLES = %w[owner admin clerk].freeze

  def fulfill?(order)
    membership = Current.membership

    return false if membership.nil?
    return false unless membership.organization_id == order.seller_organization_id

    FULFILLING_ROLES.include?(membership.role)
  end
end
