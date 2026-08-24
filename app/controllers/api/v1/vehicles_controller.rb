module Api
  module V1
    class VehiclesController < ApplicationController
      def index
        vehicles = Vehicle.order(created_at: :desc)

        render json: vehicles.map { |vehicle| VehicleSerializer.call(vehicle) }
      end

      def show
        vehicle = Vehicle.find(params[:id])

        render json: VehicleSerializer.call(vehicle, include_part_types: true)
      end

      def create
        vehicle = Vehicle.new(vehicle_params)

        if vehicle.save
          render json: VehicleSerializer.call(vehicle), status: :created
        else
          render json: { errors: camelized_errors(vehicle) }, status: :unprocessable_content
        end
      end

      private

      def vehicle_params
        underscored_params.require(:vehicle).permit(
          :vehicle_type, :make, :model, :model_year, :vin, :plate,
          :usage_value, :usage_unit, :city, specs: {}
        )
      end
    end
  end
end
