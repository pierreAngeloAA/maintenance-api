module Diagnostics
  # Arma el diagnostico mensual de un vehiculo.
  #
  # Junta tres cosas que ya existen por separado: lo que predice el motor de
  # confiabilidad, lo que midio el tecnico en la ultima visita y los vencimientos
  # que trae el RUNT. De las tres, la ultima es la mas accionable y la unica que
  # no depende de que haya talleres en la red.
  class HealthReportGeneration
    def initialize(vehicle, period: HealthReport.period_for)
      @vehicle = vehicle
      @period = period
    end

    def call
      report = HealthReport.find_or_initialize_by(vehicle: vehicle, period: period)
      report.assign_attributes(payload: payload, generated_at: Time.current)
      report.save!

      report
    end

    private

    attr_reader :vehicle, :period

    def payload
      {
        "usageValue" => vehicle.usage_value.to_f,
        "usageUnit" => vehicle.usage_unit,
        "risks" => risks,
        "inspection" => inspection_summary,
        "documents" => documents
      }
    end

    def risks
      Reliability::RiskCalculator.new(vehicle).call.map do |risk|
        RiskSerializer.call(risk).deep_stringify_keys
      end
    end

    # Si no hubo visita se dice explicitamente, en vez de omitirlo: el cliente
    # tiene que poder distinguir "esta bien" de "nadie lo ha mirado".
    def inspection_summary
      inspection = Inspection.latest_for(vehicle)
      return { "present" => false } if inspection.nil?

      {
        "present" => true,
        "id" => inspection.id,
        "performedAt" => inspection.performed_at,
        "usageValue" => inspection.usage_value.to_f,
        "observations" => inspection.observations.map { |o|
          ObservationSerializer.call(o).deep_stringify_keys
        }
      }
    end

    def documents
      {
        "soatExpiresOn" => vehicle.soat_expires_on,
        "technicalInspectionExpiresOn" => vehicle.technical_inspection_expires_on,
        "runtCheckedAt" => vehicle.runt_checked_at
      }
    end
  end
end
