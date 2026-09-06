module Diagnostics
  # El diagnostico mensual que recibe el cliente suscrito.
  #
  # Lo calcula el motor, no una visita presencial: a costo marginal cero.
  # Regalar un diagnostico presencial cada mes haria que cada cliente nuevo
  # generara un pago de salida todos los meses, y el gasto creceria igual de
  # rapido que los suscriptores.
  #
  # Se guarda en vez de calcularse al vuelo porque el cliente tiene que poder ver
  # como venia su vehiculo hace tres meses, y porque es la unica forma de
  # comparar despues contra lo que se predijo entonces.
  class HealthReport < ApplicationRecord
    belongs_to :vehicle, class_name: "Garage::Vehicle"

    validates :period, :generated_at, presence: true
    validates :period, uniqueness: { scope: :vehicle_id }

    scope :recent_first, -> { order(period: :desc) }

    def self.period_for(date = Date.current)
      date.beginning_of_month
    end
  end
end
