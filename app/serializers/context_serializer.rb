# Los contextos en los que una persona puede actuar.
#
# El de cliente lo tiene todo el mundo: no depende de ninguna membresia, porque
# cualquiera puede registrar su vehiculo. Los demas salen de las membresias ya
# aceptadas. La app usa esto para decidir si entra directo o muestra selector.
module ContextSerializer
  module_function

  CLIENT = { kind: "client" }.freeze

  def call(user)
    memberships = user.memberships.accepted.includes(:organization)

    [ CLIENT ] + memberships.map { |membership| for_membership(membership) }
  end

  def for_membership(membership)
    organization = membership.organization

    {
      kind: organization.kind,
      organizationId: organization.id,
      name: organization.name,
      role: membership.role
    }
  end
end
