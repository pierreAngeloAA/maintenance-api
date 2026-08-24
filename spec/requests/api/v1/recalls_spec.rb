require "rails_helper"

RSpec.describe "Api::V1::Recalls", type: :request do
  let(:json) { response.parsed_body }
  let(:vehicle) { create(:vehicle, make: "Honda", model: "Accord", model_year: 2020) }

  def stub_recalls(results)
    stub_request(:get, /api.nhtsa.gov/).to_return(
      status: 200,
      body: { "Count" => results.size, "results" => results }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "devuelve los recalls del vehiculo en camelCase" do
    stub_recalls([ {
      "NHTSACampaignNumber" => "20V771000",
      "Manufacturer" => "Honda (American Honda Motor Co.)",
      "Component" => "ELECTRICAL SYSTEM",
      "Summary" => "Resumen del recall",
      "Consequence" => "Consecuencia",
      "Remedy" => "Solucion",
      "ReportReceivedDate" => "10/12/2020",
      "parkIt" => false,
      "parkOutSide" => true
    } ])

    get "/api/v1/vehicles/#{vehicle.id}/recalls"

    expect(response).to have_http_status(:ok)
    recall = json["recalls"].first
    expect(recall["campaignNumber"]).to eq("20V771000")
    expect(recall["component"]).to eq("ELECTRICAL SYSTEM")
    expect(recall["reportedOn"]).to eq("2020-10-12")
    expect(recall["parkOutside"]).to be(true)
  end

  it "responde 200 con lista vacia cuando NHTSA no cubre el vehiculo" do
    # Caso colombiano: no encontrar recalls no es un error.
    stub_recalls([])

    get "/api/v1/vehicles/#{vehicle.id}/recalls"

    expect(response).to have_http_status(:ok)
    expect(json["recalls"]).to eq([])
  end

  it "responde 200 con lista vacia cuando NHTSA esta caida" do
    stub_request(:get, /api.nhtsa.gov/).to_timeout

    get "/api/v1/vehicles/#{vehicle.id}/recalls"

    expect(response).to have_http_status(:ok)
    expect(json["recalls"]).to eq([])
  end

  it "responde 404 cuando el vehiculo no existe" do
    get "/api/v1/vehicles/0/recalls"

    expect(response).to have_http_status(:not_found)
  end
end
