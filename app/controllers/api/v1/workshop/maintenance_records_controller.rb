module Api
  module V1
    module Workshop
      # El taller registra mantenimientos a nombre del cliente.
      class MaintenanceRecordsController < BaseController
        def index
          authorize VehiclePolicy.read?(vehicle)
          return if performed?

          records = vehicle.maintenance_records
            .includes(:part_type)
            .order(performed_on: :desc, id: :desc)

          render json: records.map { |record| MaintenanceRecordSerializer.call(record) }
        end

        def create
          authorize VehiclePolicy.write?(vehicle)
          return if performed?

          record = vehicle.maintenance_records.new(maintenance_record_params)

          if record.save
            render json: MaintenanceRecordSerializer.call(record), status: :created
          else
            render json: { errors: camelized_errors(record) }, status: :unprocessable_content
          end
        end

        private

        # Sin ningun permiso el vehiculo no existe para este taller: 404, no 403.
        def vehicle
          @vehicle ||= Garage::Vehicle
            .accessible_by(Current.organization)
            .find(params[:vehicle_id])
        end

        def maintenance_record_params
          underscored_params.require(:maintenance_record).permit(
            :part_type_id, :performed_on, :usage_at_service,
            :part_brand, :cost_cents, :currency, :notes, :catalog_product_id
          )
        end
      end
    end
  end
end
