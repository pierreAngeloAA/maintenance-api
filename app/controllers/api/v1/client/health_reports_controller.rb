module Api
  module V1
    module Client
      # El diagnostico mensual del vehiculo, y los de los meses anteriores.
      class HealthReportsController < ApplicationController
        # El alcance ya lo pone la consulta: current_user.vehicles.
        skip_authorization

        def index
          reports = vehicle.health_reports.recent_first

          render json: reports.map { |report| HealthReportSerializer.call(report) }
        end

        # El del mes en curso. Se genera al pedirlo si todavia no existe: el
        # calculo es barato y asi el cliente nunca ve una pantalla vacia por
        # culpa de un job que no ha corrido.
        def show
          report = Diagnostics::HealthReportGeneration.new(vehicle).call

          render json: HealthReportSerializer.call(report)
        end

        private

        def vehicle
          @vehicle ||= current_user.vehicles.find(params[:vehicle_id])
        end
      end
    end
  end
end
