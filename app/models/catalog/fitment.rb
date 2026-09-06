module Catalog
  # Para que vehiculos sirve un producto.
  #
  # **La compatibilidad es la parte dificil de verdad** del comercio de
  # repuestos: es donde la gente compra mal y devuelve. Los catalogos serios
  # (TecDoc y similares) son productos enteros por si solos, asi que aca se
  # empieza con compatibilidad gruesa —tipo + marca + linea + rango de anos— que
  # alcanza para decir "sirve para tu Logan 2019" sin prometer una precision que
  # no tenemos.
  #
  # `make` y `model` nulos significan "cualquiera": permite declarar que una
  # pastilla sirve para todas las motos sin enumerar cada linea.
  class Fitment < ApplicationRecord
    belongs_to :product

    validates :vehicle_type, presence: true,
      inclusion: { in: ->(_) { Garage::Vehicle.vehicle_types.keys } }
    validates :year_from, :year_to,
      numericality: { only_integer: true, allow_nil: true,
                      greater_than_or_equal_to: Garage::Vehicle::OLDEST_MODEL_YEAR }
    validate :year_range_is_coherent

    normalizes :make, with: ->(make) { make.strip.presence }
    normalizes :model, with: ->(model) { model.strip.presence }

    # La comparacion de marca y linea es insensible a mayusculas: el almacen
    # escribe "Renault" y el usuario registro "RENAULT".
    scope :matching, ->(vehicle) {
      where(vehicle_type: vehicle.vehicle_type)
        .where("make IS NULL OR lower(make) = lower(?)", vehicle.make)
        .where("model IS NULL OR lower(model) = lower(?)", vehicle.model)
        .where("year_from IS NULL OR year_from <= ?", vehicle.model_year)
        .where("year_to IS NULL OR year_to >= ?", vehicle.model_year)
    }

    private

    def year_range_is_coherent
      return if year_from.blank? || year_to.blank? || year_from <= year_to

      errors.add(:year_to, :greater_than_or_equal_to, count: year_from)
    end
  end
end
