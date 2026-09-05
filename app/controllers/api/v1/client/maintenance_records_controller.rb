module Api
  module V1
    module Client
      # Historial de mantenimientos del vehiculo: la data que alimenta el modelo
      # de riesgo y la que ninguna API externa puede darnos.
      class MaintenanceRecordsController < ApplicationController
        # El alcance ya lo pone la consulta: current_user.vehicles.
        skip_authorization

        def index
          records = vehicle.maintenance_records
            .includes(:part_type)
            .order(performed_on: :desc, id: :desc)

          render json: records.map { |record| MaintenanceRecordSerializer.call(record) }
        end

        def create
          record = vehicle.maintenance_records.new(maintenance_record_params)

          if record.save
            render json: MaintenanceRecordSerializer.call(record), status: :created
          else
            render json: { errors: camelized_errors(record) }, status: :unprocessable_content
          end
        end

        private

        def vehicle
          @vehicle ||= current_user.vehicles.find(params[:vehicle_id])
        end

        def maintenance_record_params
          underscored_params.require(:maintenance_record).permit(
            :part_type_id, :performed_on, :usage_at_service,
            :part_brand, :cost_cents, :currency, :notes
          )
        end
      end
    end
  end
end
