module OrganizationSerializer
  module_function

  def call(organization)
    {
      id: organization.id,
      kind: organization.kind,
      name: organization.name,
      nit: organization.nit,
      city: organization.city,
      # `pending` hasta que se verifique: la app puede avisarlo.
      status: organization.status,
      verifiedAt: organization.verified_at,
      createdAt: organization.created_at
    }
  end
end
