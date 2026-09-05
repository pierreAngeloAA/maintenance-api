module Api
  module V1
    module Client
      # Recalls de seguridad de un vehiculo.
      #
      # Siempre responde 200 con una lista, aunque este vacia: NHTSA solo cubre
      # vehiculos homologados en EE.UU., asi que no encontrar recalls es un
      # resultado normal y no un error.
      class RecallsController < ApplicationController
        # El alcance ya lo pone la consulta: current_user.vehicles.
        skip_authorization

        def show
          vehicle = current_user.vehicles.find(params[:vehicle_id])
          recalls = Nhtsa::RecallsFetcher.new.call(
            make: vehicle.make,
            model: vehicle.model,
            model_year: vehicle.model_year
          )

          render json: {
            vehicleId: vehicle.id,
            recalls: recalls.map { |recall| RecallSerializer.call(recall) }
          }
        end
      end
    end
  end
end
