module Api
  module V1
    module Client
      # Lo que el cliente pide para su vehiculo.
      class ServiceRequestsController < ApplicationController
        # El alcance ya lo pone la consulta: current_user.vehicles.
        skip_authorization

        def index
          requests = Services::Request
            .where(vehicle: current_user.vehicles)
            .order(created_at: :desc)

          render json: requests.map { |request| ServiceRequestSerializer.call(request) }
        end

        def create
          request = Services::Request.new(
            service_request_params.merge(vehicle: vehicle, requested_by_user: current_user)
          )

          if request.save
            # Ponerla frente a los talleres cercanos es parte de crearla: una
            # solicitud que nadie ve no le sirve a nadie.
            Services::RequestBroadcast.new(request).call
            render json: ServiceRequestSerializer.call(request), status: :created
          else
            render json: { errors: camelized_errors(request) }, status: :unprocessable_content
          end
        end

        # Cancelar cierra la orden si ya la tomaron, y con ella el permiso.
        def destroy
          request = Services::Request.where(vehicle: current_user.vehicles).find(params[:id])

          if request.order
            Services::OrderTransition.new(request.order, "canceled").call
          else
            request.update!(status: "canceled")
            request.offers.update_all(status: "expired")
          end

          head :no_content
        end

        private

        def vehicle
          @vehicle ||= current_user.vehicles.find(service_request_params_vehicle_id)
        end

        def service_request_params_vehicle_id
          underscored_params.require(:service_request).require(:vehicle_id)
        end

        def service_request_params
          underscored_params.require(:service_request).permit(
            :kind, :scheduled_for, :address, :latitude, :longitude, :notes
          )
        end
      end
    end
  end
end
