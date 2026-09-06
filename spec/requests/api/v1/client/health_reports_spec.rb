require "rails_helper"

RSpec.describe "Api::V1::Client::HealthReports", type: :request do
  def json = response.parsed_body

  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:vehicle) { create(:vehicle, :motorcycle, user: user, usage_value: 18_000) }

  before do
    chain = create(:part_type, :drive_chain)
    create(:reliability_profile, part_type: chain, vehicle_type: "motorcycle",
      weibull_shape: 2, characteristic_life: 20_000, life_unit: "km")
  end

  it "responde 401 sin token" do
    get "/api/v1/client/vehicles/#{vehicle.id}/health_report"

    expect(response).to have_http_status(:unauthorized)
  end

  # Que un job no haya corrido no puede dejar al cliente sin nada que ver.
  it "genera el diagnostico del mes al pedirlo si no existe" do
    expect { get "/api/v1/client/vehicles/#{vehicle.id}/health_report", headers: headers }
      .to change(Diagnostics::HealthReport, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(json["risks"]).to be_present
  end

  it "no genera otro si el del mes ya existe" do
    get "/api/v1/client/vehicles/#{vehicle.id}/health_report", headers: headers

    expect { get "/api/v1/client/vehicles/#{vehicle.id}/health_report", headers: headers }
      .not_to change(Diagnostics::HealthReport, :count)
  end

  it "lista el historial, del mas reciente al mas viejo" do
    Diagnostics::HealthReportGeneration.new(vehicle).call
    Diagnostics::HealthReportGeneration.new(vehicle, period: 2.months.ago.beginning_of_month).call

    get "/api/v1/client/vehicles/#{vehicle.id}/health_reports", headers: headers

    expect(json.length).to eq(2)
    expect(json.first["period"]).to be > json.last["period"]
  end

  it "no deja ver el diagnostico del vehiculo de otro" do
    get "/api/v1/client/vehicles/#{create(:vehicle).id}/health_report", headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
