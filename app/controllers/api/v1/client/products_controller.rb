module Api
  module V1
    module Client
      # Los repuestos que sirven para el vehiculo del cliente.
      class ProductsController < ApplicationController
        # El alcance ya lo pone la consulta: current_user.vehicles.
        skip_authorization

        def index
          products = Catalog::Product
            .available
            .for_vehicle(vehicle)
            .includes(:part_type, :organization)
            .order(:unit_price_cents)

          render json: products.map { |product| ProductSerializer.call(product) }
        end

        private

        def vehicle
          @vehicle ||= current_user.vehicles.find(params[:vehicle_id])
        end
      end
    end
  end
end
