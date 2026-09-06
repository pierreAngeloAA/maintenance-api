module Api
  module V1
    module Workshop
      # Cada medicion del checklist. Se guardan una por una a medida que el
      # tecnico avanza, no todas al final: si se le cierra la app a mitad de la
      # visita, lo que ya midio no se pierde.
      class ObservationsController < BaseController
        def create
          authorize VehiclePolicy.write?(inspection.vehicle)
          return if performed?

          observation = inspection.observations
            .find_or_initialize_by(item_id: observation_params[:item_id])
          observation.assign_attributes(observation_params)

          if observation.save
            render json: ObservationSerializer.call(observation), status: :created
          else
            render json: { errors: camelized_errors(observation) },
              status: :unprocessable_content
          end
        end

        private

        def inspection
          @inspection ||= Diagnostics::Inspection
            .where(organization: Current.organization)
            .find(params[:inspection_id])
        end

        def observation_params
          underscored_params.require(:observation).permit(
            :item_id, :numeric_value, :scale_value, :boolean_value, :date_value,
            :severity, :notes
          )
        end
      end
    end
  end
end
