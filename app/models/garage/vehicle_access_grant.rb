module Garage
  # Permiso temporal de una organizacion sobre el vehiculo de un cliente.
  #
  # Es lo que hace posible que el taller registre mantenimientos y diagnosticos
  # a nombre del cliente sin que el vehiculo deje de ser suyo. El modelo es el de
  # una clinica con las historias clinicas: acceso acotado, con fecha, trazable y
  # revocable por el paciente.
  #
  # El campo se llama `access_level` y no `scope` porque `scope` es un metodo de
  # clase de Active Record.
  class VehicleAccessGrant < ApplicationRecord
    ACCESS_LEVELS = { read: "read", write: "write" }.freeze

    belongs_to :vehicle
    belongs_to :organization, class_name: "Identity::Organization"
    belongs_to :granted_by, class_name: "User"
    # Cuando nace de un servicio, muere con el.
    belongs_to :service_order, class_name: "Services::Order", optional: true

    enum :access_level, ACCESS_LEVELS, validate: true, prefix: :access

    validates :access_level, :granted_at, presence: true
    validates :vehicle_id, uniqueness: { scope: :organization_id, conditions: -> { active } }

    scope :active, -> {
      where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current)
    }

    # Escribir incluye leer: quien registra un mantenimiento necesita ver el historial.
    scope :allowing, ->(level) {
      level.to_s == "write" ? where(access_level: "write") : all
    }

    def revoke!
      update!(revoked_at: Time.current)
    end
  end
end
