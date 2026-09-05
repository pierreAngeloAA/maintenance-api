module Garage
  # Un mantenimiento que el usuario ya hizo: que pieza cambio, cuando y con cuanto
  # uso encima.
  #
  # Esta tabla es la data que genera la ventaja competitiva del producto: no existe
  # en ninguna API externa, y es la que alimenta el modelo de riesgo (el uso desde
  # el ultimo cambio de cada pieza).
  class MaintenanceRecord < ApplicationRecord
    belongs_to :vehicle
    belongs_to :part_type

    validates :performed_on, presence: true
    validates :usage_at_service, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cost_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    validate :performed_on_is_not_in_the_future
    validate :usage_at_service_within_vehicle_usage
    validate :part_type_applies_to_vehicle

    # El ultimo mantenimiento de cada pieza, que es el que define el uso acumulado
    # desde el cambio.
    scope :latest_per_part_type, -> {
      select("DISTINCT ON (part_type_id) maintenance_records.*")
        .order(:part_type_id, usage_at_service: :desc, performed_on: :desc)
    }

    private

    def performed_on_is_not_in_the_future
      return if performed_on.blank?
      return if performed_on <= Date.current

      # El count no es decorativo: sin el, el mensaje revienta al renderizar el 422.
      errors.add(:performed_on, :less_than_or_equal_to, count: Date.current)
    end

    def usage_at_service_within_vehicle_usage
      return if usage_at_service.blank? || vehicle.blank? || vehicle.usage_value.blank?
      return if usage_at_service <= vehicle.usage_value

      errors.add(:usage_at_service, :less_than_or_equal_to, count: vehicle.usage_value)
    end

    # No se le cambia la cadena a un auto.
    def part_type_applies_to_vehicle
      return if part_type.blank? || vehicle.blank?
      return if part_type.applicable_vehicle_types.include?(vehicle.vehicle_type)

      errors.add(:part_type, :inclusion)
    end
  end
end
