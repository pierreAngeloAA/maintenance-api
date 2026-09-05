module Api
  module V1
    module Client
      # El vehiculo y su historial son del cliente: tiene que poder ver quien
      # tiene acceso y quitarlo cuando quiera.
      class AccessGrantsController < ApplicationController
        # El alcance ya lo pone la consulta: current_user.vehicles.
        skip_authorization

        def index
          grants = vehicle.access_grants.active.includes(:organization).order(granted_at: :desc)

          render json: grants.map { |grant| AccessGrantSerializer.call(grant) }
        end

        def create
          grant = vehicle.access_grants.new(access_grant_params.merge(
            granted_by: current_user, granted_at: Time.current
          ))

          if grant.save
            render json: AccessGrantSerializer.call(grant), status: :created
          else
            render json: { errors: camelized_errors(grant) }, status: :unprocessable_content
          end
        end

        def destroy
          vehicle.access_grants.active.find(params[:id]).revoke!

          head :no_content
        end

        private

        def vehicle
          @vehicle ||= current_user.vehicles.find(params[:vehicle_id])
        end

        def access_grant_params
          underscored_params.require(:access_grant).permit(:organization_id, :access_level)
        end
      end
    end
  end
end
