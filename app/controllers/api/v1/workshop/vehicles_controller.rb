module Api
  module V1
    module Workshop
      # Los vehiculos que el taller puede tocar: los que tienen un permiso
      # vigente otorgado por su dueno, ni uno mas.
      class VehiclesController < BaseController
        # El alcance ya lo pone la consulta: solo los vehiculos con permiso vigente.
        skip_authorization only: :index

        def index
          vehicles = accessible_vehicles.order(created_at: :desc)

          render json: vehicles.map { |vehicle| VehicleSerializer.call(vehicle) }
        end

        def show
          vehicle = accessible_vehicles.find(params[:id])
          authorize VehiclePolicy.read?(vehicle)
          return if performed?

          render json: VehicleSerializer.call(vehicle, include_part_types: true)
        end

        private

        # Un vehiculo sin permiso responde 404 y no 403: contestar distinto
        # delataria que existe, y un taller no tiene por que poder averiguar
        # que placas hay en el sistema.
        def accessible_vehicles
          Garage::Vehicle.accessible_by(Current.organization)
        end
      end
    end
  end
end
