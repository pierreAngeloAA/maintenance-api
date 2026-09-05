module Api
  module V1
    # Alta de talleres y almacenes. No cuelga de ninguna audiencia: es la puerta
    # por la que un cliente se convierte tambien en taller o almacen, sin crear
    # otra cuenta.
    class OrganizationsController < ApplicationController
      # Cualquiera con sesion puede registrar su taller o su almacen: es como se
      # vuelve proveedor sin abrir otra cuenta.
      skip_authorization only: :create

      def create
        organization = Identity::OrganizationRegistration.new(current_user, organization_params).call

        if organization.persisted?
          render json: OrganizationSerializer.call(organization), status: :created
        else
          render json: { errors: camelized_errors(organization) }, status: :unprocessable_content
        end
      end

      def update
        organization = Identity::Organization.find(params[:id])
        authorize OrganizationPolicy.manage?(organization)
        return if performed?

        if organization.update(organization_params)
          render json: OrganizationSerializer.call(organization)
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
