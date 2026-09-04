require "rails_helper"

RSpec.describe "Api::V1::VinLookups", type: :request do
  let(:json) { response.parsed_body }
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  def stub_nhtsa(results)
    stub_request(:get, /vpic.nhtsa.dot.gov/)
      .to_return(
        status: 200,
        body: { "Results" => results }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  it "devuelve los datos decodificados cuando NHTSA conoce el vehiculo" do
    stub_nhtsa([ { "Make" => "TESLA", "Model" => "Model 3", "ModelYear" => "2023", "VehicleType" => "PASSENGER CAR" } ])

    get "/api/v1/vin_lookups/5YJ3E1EA6PF384836", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["found"]).to be(true)
    expect(json["make"]).to eq("TESLA")
    expect(json["modelYear"]).to eq(2023)
    expect(json["vehicleType"]).to eq("car")
  end

  it "responde 200 con found en false cuando NHTSA no conoce el vehiculo" do
    # Caso colombiano: no es un error, es que NHTSA solo cubre EE.UU.
    stub_nhtsa([ { "Make" => "", "Model" => "", "ModelYear" => "", "VehicleType" => "" } ])

    get "/api/v1/vin_lookups/9FBLSRB56KM123456", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["found"]).to be(false)
    expect(json["make"]).to be_nil
  end

  it "responde 200 y no consulta el API si el VIN tiene mal formato" do
    get "/api/v1/vin_lookups/NOTAVIN", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["found"]).to be(false)
    expect(a_request(:get, /vpic.nhtsa.dot.gov/)).not_to have_been_made
  end

  it "responde 200 con found en false cuando el API esta caida" do
    stub_request(:get, /vpic.nhtsa.dot.gov/).to_timeout

    get "/api/v1/vin_lookups/5YJ3E1EA6PF384836", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["found"]).to be(false)
  end

  it "devuelve el VIN consultado, normalizado" do
    stub_nhtsa([])

    get "/api/v1/vin_lookups/5yj3e1ea6pf384836", headers: headers

    expect(json["vin"]).to eq("5YJ3E1EA6PF384836")
  end
end
