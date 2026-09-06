require "rails_helper"

RSpec.describe Diagnostics::HealthReportGeneration do
  let(:vehicle) { create(:vehicle, :motorcycle, usage_value: 18_000) }
  let(:chain) { create(:part_type, :drive_chain) }

  before do
    create(:reliability_profile, part_type: chain, vehicle_type: "motorcycle",
      weibull_shape: 2, characteristic_life: 20_000, life_unit: "km")
  end

  it "guarda el riesgo por pieza que calcula el motor" do
    report = described_class.new(vehicle).call

    expect(report.payload["risks"].first).to include("partType", "conditionalRisk")
  end

  it "queda fechado en el mes en curso" do
    report = described_class.new(vehicle).call

    expect(report.period).to eq(Date.current.beginning_of_month)
    expect(report.generated_at).to be_present
  end

  # Volver a generarlo actualiza el del mes, no crea otro.
  it "no duplica el reporte del mismo mes" do
    described_class.new(vehicle).call

    expect { described_class.new(vehicle).call }.not_to change(Diagnostics::HealthReport, :count)
  end

  it "guarda un reporte por mes" do
    described_class.new(vehicle).call
    described_class.new(vehicle, period: 1.month.ago.beginning_of_month).call

    expect(vehicle.health_reports.count).to eq(2)
  end

  describe "la ultima visita" do
    # El cliente tiene que poder distinguir "esta bien" de "nadie lo ha mirado".
    it "dice explicitamente que no hubo visita" do
      report = described_class.new(vehicle).call

      expect(report.payload["inspection"]).to eq({ "present" => false })
    end

    it "incluye lo medido y de cuando es" do
      inspection = create(:inspection, :completed, vehicle: vehicle, performed_at: 3.days.ago)

      report = described_class.new(vehicle).call

      expect(report.payload["inspection"]).to include("present" => true)
      expect(report.payload["inspection"]["observations"]).to be_present
      expect(report.payload["inspection"]["performedAt"]).to be_present
    end

    it "usa la mas reciente" do
      create(:inspection, :completed, vehicle: vehicle, performed_at: 2.months.ago)
      reciente = create(:inspection, :completed, vehicle: vehicle, performed_at: 1.day.ago)

      report = described_class.new(vehicle).call

      expect(report.payload["inspection"]["id"]).to eq(reciente.id)
    end

    it "ignora las que quedaron abiertas" do
      create(:inspection, vehicle: vehicle)

      report = described_class.new(vehicle).call

      expect(report.payload["inspection"]).to eq({ "present" => false })
    end
  end

  # Lo unico con fecha dura y consecuencia legal, y no depende de la red.
  it "incluye los vencimientos del RUNT" do
    vehicle.update!(soat_expires_on: Date.new(2027, 3, 15),
      technical_inspection_expires_on: Date.new(2027, 1, 20))

    report = described_class.new(vehicle).call

    expect(report.payload["documents"]).to include(
      "soatExpiresOn" => "2027-03-15", "technicalInspectionExpiresOn" => "2027-01-20"
    )
  end

  it "guarda el uso del vehiculo al momento del reporte" do
    report = described_class.new(vehicle).call

    expect(report.payload).to include("usageValue" => 18_000.0, "usageUnit" => "km")
  end
end
