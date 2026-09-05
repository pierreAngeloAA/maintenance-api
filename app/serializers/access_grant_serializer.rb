module AccessGrantSerializer
  module_function

  def call(grant)
    {
      id: grant.id,
      accessLevel: grant.access_level,
      grantedAt: grant.granted_at,
      expiresAt: grant.expires_at,
      organization: {
        id: grant.organization.id,
        kind: grant.organization.kind,
        name: grant.organization.name
      }
    }
  end
end
