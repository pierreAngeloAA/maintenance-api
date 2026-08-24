module Api
  module V1
    # Autocompletado del formulario de registro a partir del VIN.
    #
    # Siempre responde 200: que NHTSA no conozca el vehiculo (tipico en
    # Colombia) no es un error del cliente ni del servidor, es informacion.
    class VinLookupsController < ApplicationController
      def show
        vin = params[:vin].to_s.gsub(/\s+/, "").upcase
        result = Nhtsa::VinDecoder.new.call(vin)

        render json: {
          vin: vin,
          found: result.found?,
          make: result.make,
          model: result.model,
          modelYear: result.model_year,
          vehicleType: result.vehicle_type
        }
      end
    end
  end
end
