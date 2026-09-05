module Runt
  # Enriquece un vehiculo con lo que sabe el RUNT.
  #
  # Va en background porque la primera consulta de una placa tarda 30-90
  # segundos: meter eso en el ciclo del request seria tumbar el servidor.
  class VehicleLookupJob < ApplicationJob
    queue_as :default

    def perform(vehicle_id)
      vehicle = Garage::Vehicle.find_by(id: vehicle_id)
      return if vehicle.nil? || vehicle.plate.blank?

      result = PlacapiClient.new.call(vehicle.plate)

      vehicle.update!(
        # Enriquecimiento, no correccion: lo que el usuario escribio manda, y
        # solo se completan los vencimientos, que el no puede saber de memoria.
        soat_expires_on: result.soat_expires_on || vehicle.soat_expires_on,
        technical_inspection_expires_on:
          result.technical_inspection_expires_on || vehicle.technical_inspection_expires_on,
        runt_checked_at: Time.current
      )
    end
  end
end
