module HealthReportSerializer
  module_function

  def call(report)
    {
      id: report.id,
      vehicleId: report.vehicle_id,
      period: report.period,
      generatedAt: report.generated_at,
      **report.payload.symbolize_keys
    }
  end
end
