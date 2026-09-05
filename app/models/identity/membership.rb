module Identity
  # La relacion entre una persona y una organizacion. El rol no es un campo de la
  # cuenta sino de esta relacion: por eso una misma persona puede ser cliente de
  # su moto, tecnico de un taller y vendedor de un almacen con un solo correo.
  class Membership < ApplicationRecord
    ROLES = {
      owner: "owner",
      admin: "admin",
      technician: "technician",
      clerk: "clerk"
    }.freeze

    belongs_to :user
    belongs_to :organization

    enum :role, ROLES, validate: true

    validates :role, presence: true
    validates :user_id, uniqueness: { scope: :organization_id }

    # Una invitacion no da permisos hasta que la persona la acepta. Sin esto
    # cualquiera podria declararse tecnico de un taller ajeno y tomar servicios
    # en su nombre.
    scope :accepted, -> { where.not(accepted_at: nil) }
  end
end
