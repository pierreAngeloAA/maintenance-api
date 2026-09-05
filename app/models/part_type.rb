# Catalogo de tipos de pieza. Las piezas nunca se hardcodean en el codigo: una
# moto lleva cadena y kit de arrastre, un auto lleva correa de repartición, y una
# clase nueva de vehiculo entra insertando filas, no tocando codigo.
class PartType < ApplicationRecord
  CATEGORIES = %w[
    engine
    transmission
    brakes
    tires
    electrical
    suspension
    fluids
    filters
    lighting
  ].freeze

  has_many :reliability_profiles, class_name: "Reliability::ReliabilityProfile", dependent: :destroy

  normalizes :code, with: ->(code) { code.strip.downcase }

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :applicable_vehicle_types, presence: true

  validate :applicable_vehicle_types_are_supported

  scope :for_vehicle_type, ->(vehicle_type) {
    where("? = ANY(applicable_vehicle_types)", vehicle_type)
  }

  private

  def applicable_vehicle_types_are_supported
    unsupported = applicable_vehicle_types.to_a - Garage::Vehicle.vehicle_types.keys

    errors.add(:applicable_vehicle_types, :inclusion) if unsupported.any?
  end
end
