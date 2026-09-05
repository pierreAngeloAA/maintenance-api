module Garage
  class Vehicle < ApplicationRecord
    # Clases de vehiculo soportadas hoy. La app puede crecer a otras (incluidas
    # aereas y maritimas) agregando valores: por eso el enum es de strings y no
    # de enteros, para que no dependa del orden.
    VEHICLE_TYPES = { car: "car", motorcycle: "motorcycle" }.freeze
    USAGE_UNITS = { km: "km", hours: "hours" }.freeze

    # Vehiculos que se miden por distancia recorrida.
    LAND_VEHICLE_TYPES = %w[car motorcycle].freeze
    LAND_USAGE_UNIT = "km".freeze

    # El estandar ISO 3779 excluye I, O y Q para no confundirlas con 1 y 0.
    VIN_FORMAT = /\A[A-HJ-NPR-Z0-9]{17}\z/
    OLDEST_MODEL_YEAR = 1900

    belongs_to :user

    has_many :maintenance_records, dependent: :destroy

    enum :vehicle_type, VEHICLE_TYPES, validate: true
    enum :usage_unit, USAGE_UNITS, validate: true

    normalizes :vin, with: ->(vin) { vin.gsub(/\s+/, "").upcase }
    normalizes :plate, with: ->(plate) { plate.gsub(/\s+/, "").upcase }

    validates :vehicle_type, :usage_unit, presence: true
    validates :make, :model, presence: true
    validates :model_year,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: OLDEST_MODEL_YEAR,
        less_than_or_equal_to: ->(_vehicle) { Date.current.year + 1 }
      }
    validates :vin,
      format: { with: VIN_FORMAT },
      uniqueness: true,
      allow_nil: true
    validates :usage_value, numericality: { greater_than_or_equal_to: 0 }

    validate :usage_unit_matches_vehicle_type

    # Piezas del catalogo que aplican a esta clase de vehiculo.
    def part_types
      PartType.for_vehicle_type(vehicle_type)
    end

    private

    def usage_unit_matches_vehicle_type
      return unless LAND_VEHICLE_TYPES.include?(vehicle_type)
      return if usage_unit == LAND_USAGE_UNIT

      errors.add(:usage_unit, :inclusion)
    end
  end
end
