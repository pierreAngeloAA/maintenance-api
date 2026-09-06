module Api
  module V1
    module Workshop
      # La visita de 30 minutos.
      class InspectionsController < BaseController
        def show
          authorize VehiclePolicy.read?(inspection.vehicle)
          return if performed?

          render json: InspectionSerializer.call(inspection, include_items: true)
        end

        # Abre la inspeccion con la plantilla vigente para esa clase de vehiculo.
        def create
          authorize VehiclePolicy.write?(vehicle)
          return if performed?

          result = Diagnostics::InspectionOpening.new(
            vehicle: vehicle, technician: current_user,
            organization: Current.organization, attributes: inspection_params
          ).call

          if result.success?
            render json: InspectionSerializer.call(result.inspection, include_items: true),
              status: :created
          else
            render json: { error: result.error }, status: :unprocessable_content
          end
        end

        # Cerrarla exige la evidencia: sin foto, sin ubicacion o sin mediciones
        # no hay visita que valga.
        def update
          authorize VehiclePolicy.write?(inspection.vehicle)
          return if performed?

          inspection.photos.attach(params[:photos]) if params[:photos].present?
          inspection.assign_attributes(close_params.merge(
            status: "completed", performed_at: Time.current,
            duration_seconds: (Time.current - inspection.started_at).round
          ))

          if inspection.save
            render json: InspectionSerializer.call(inspection)
          else
            render json: { errors: camelized_errors(inspection) },
              status: :unprocessable_content
          end
        end

        private

        def inspection
          @inspection ||= Diagnostics::Inspection
            .where(organization: Current.organization)
            .find(params[:id])
        end

        def vehicle
          @vehicle ||= Garage::Vehicle
            .accessible_by(Current.organization)
            .find(underscored_params.require(:inspection).require(:vehicle_id))
        end

        def inspection_params
          underscored_params.require(:inspection).permit(:usage_value, :service_order_id)
        end

        def close_params
          underscored_params.fetch(:inspection, {}).permit(:latitude, :longitude, :summary)
        end
      end
    end
  end
end
