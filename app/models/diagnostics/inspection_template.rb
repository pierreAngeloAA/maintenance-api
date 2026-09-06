module Diagnostics
  # El checklist, versionado.
  #
  # Se versiona en vez de editarse en sitio porque va a cambiar, y las
  # mediciones viejas tienen que seguir siendo comparables: una lectura de 4,5 mm
  # solo se puede comparar contra otra tomada con el mismo criterio.
  class InspectionTemplate < ApplicationRecord
    # El orden es el de la visita, que lo marca `position`. Ordenar por `phase`
    # lo dejaria alfabetico: driving antes que engine_off.
    has_many :items, -> { order(:position) },
      class_name: "Diagnostics::InspectionItem", foreign_key: :template_id,
      dependent: :destroy
    has_many :inspections, foreign_key: :template_id, dependent: :restrict_with_error

    validates :code, :version, :vehicle_type, presence: true
    validates :version, numericality: { only_integer: true, greater_than: 0 }
    validates :code, uniqueness: { scope: :version }
    validates :vehicle_type, inclusion: { in: ->(_) { Garage::Vehicle.vehicle_types.keys } }

    scope :published, -> { where.not(published_at: nil) }

    # La vigente para una clase de vehiculo es la ultima publicada.
    def self.current_for(vehicle_type)
      published.where(vehicle_type: vehicle_type).order(version: :desc).first
    end
  end
end
