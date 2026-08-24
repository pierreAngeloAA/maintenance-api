module Api
  module V1
    # Riesgo de falla por pieza, ordenado de mayor a menor.
    class RisksController < ApplicationController
      def show
        vehicle = Vehicle.find(params[:vehicle_id])
        risks = Reliability::RiskCalculator.new(vehicle, horizon: horizon).call

        render json: {
          vehicleId: vehicle.id,
          risks: risks.map { |risk| RiskSerializer.call(risk) }
        }
      end

      private

      # Un horizonte invalido no es motivo para fallar: se ignora y se usa el
      # tramo por defecto de cada pieza.
      def horizon
        value = params[:horizon].presence&.to_f

        value if value&.positive?
      end
    end
  end
end
