# Parametros de confiabilidad de una pieza para una clase de vehiculo concreta.
#
# Modelamos la vida de cada pieza con una distribucion de Weibull:
#
#   R(t) = exp(-(t/eta)^beta)
#
# donde `t` es el uso acumulado desde el ultimo cambio, `eta` la vida
# caracteristica (el uso al que ya fallo el 63,2%) y `beta` la forma de la curva:
# beta cerca de 1 es falla aleatoria, beta mayor a 3 es desgaste marcado.
class ReliabilityProfile < ApplicationRecord
  LIFE_UNITS = %w[km hours months].freeze
  SOURCES = %w[engineering_estimate user_data].freeze

  belongs_to :part_type

  validates :vehicle_type, presence: true, inclusion: { in: ->(_) { Vehicle.vehicle_types.keys } }
  validates :weibull_shape, numericality: { greater_than: 0 }
  validates :characteristic_life, numericality: { greater_than: 0 }
  validates :life_unit, presence: true, inclusion: { in: LIFE_UNITS }
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :part_type_id, uniqueness: { scope: :vehicle_type }

  def self.for(part_type, vehicle_type)
    find_by(part_type: part_type, vehicle_type: vehicle_type)
  end

  # Probabilidad de que la pieza siga sana despues de `usage` de uso.
  def reliability_at(usage)
    usage = usage.to_f
    return 1.0 if usage <= 0

    Math.exp(-((usage / characteristic_life.to_f)**weibull_shape.to_f))
  end

  def failure_probability_at(usage)
    1.0 - reliability_at(usage)
  end

  # True cuando el parametro todavia es una estimacion de ingenieria y no un
  # numero calculado con datos reales de usuarios. La interfaz tiene que poder
  # decirlo: no inventamos precision que no tenemos.
  def estimate?
    source == "engineering_estimate"
  end
end
