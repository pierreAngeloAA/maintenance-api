module Diagnostics
  # Genera el diagnostico del mes para un vehiculo.
  #
  # Va en background porque es trabajo periodico sobre toda la flota: correrlo
  # dentro de un request no tendria sentido y el cliente no lo esta esperando.
  class MonthlyHealthReportJob < ApplicationJob
    queue_as :default

    def perform(vehicle_id)
      vehicle = Garage::Vehicle.find_by(id: vehicle_id)
      return if vehicle.nil?

      HealthReportGeneration.new(vehicle).call
    end
  end
end
