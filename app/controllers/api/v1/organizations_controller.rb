module Api
  module V1
    # Alta de talleres y almacenes. No cuelga de ninguna audiencia: es la puerta
    # por la que un cliente se convierte tambien en taller o almacen, sin crear
    # otra cuenta.
    class OrganizationsController < ApplicationController
      def create
        organization = Identity::OrganizationRegistration.new(current_user, organization_params).call

        if organization.persisted?
          render json: OrganizationSerializer.call(organization), status: :created
        else
          render json: { errors: camelized_errors(organization) }, status: :unprocessable_content
        end
      end

      private

      def organization_params
        underscored_params.require(:organization).permit(
          :kind, :name, :nit, :city, :latitude, :longitude
        )
      end
    end
  end
end
