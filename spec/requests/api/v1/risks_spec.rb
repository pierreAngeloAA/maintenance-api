require "rails_helper"

RSpec.describe "Api::V1::Risks", type: :request do
  let(:json) { response.parsed_body }
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:vehicle) { create(:vehicle, :motorcycle, user: user, usage_value: 18_000) }
  let(:chain) { create(:part_type, :drive_chain) }

  before do
    create(:reliability_profile, part_type: chain, vehicle_type: "motorcycle",
      weibull_shape: 2, characteristic_life: 20_000, life_unit: "km")
  end

  it "devuelve el riesgo de cada pieza del vehiculo" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    expect(response).to have_http_status(:ok)
    risk = json["risks"].first
    expect(risk["partType"]["code"]).to eq("drive_chain")
    expect(risk["conditionalRisk"]).to be_between(0, 1)
    expect(risk["failureProbability"]).to be_between(0, 1)
  end

  it "dice de donde salio el uso acumulado" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    expect(json["risks"].first["basis"]).to eq("vehicle_total")
  end

  it "cambia la base cuando si hay historial" do
    create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 12_000)

    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    risk = json["risks"].first
    expect(risk["basis"]).to eq("last_service")
    expect(risk["usageSinceService"]).to eq(6000.0)
  end

  it "avisa que los parametros todavia son estimaciones de ingenieria" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    expect(json["risks"].first["estimate"]).to be(true)
  end

  it "informa el ajuste por contexto que se le aplico a la pieza" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    # La factory registra el vehiculo en Bogota, ciudad montanosa: la cadena
    # dura menos que en una ciudad plana.
    expect(json["risks"].first["contextFactor"]).to be_between(0, 1).exclusive
  end

  it "informa un ajuste neutro cuando no sabemos donde rueda el vehiculo" do
    vehicle.update!(city: nil)

    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    expect(json["risks"].first["contextFactor"]).to eq(1.0)
  end

  it "informa el tramo sobre el que se calculo el riesgo condicional" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", headers: headers

    risk = json["risks"].first
    expect(risk["horizon"]).to eq(1000)
    expect(risk["lifeUnit"]).to eq("km")
  end

  it "acepta un tramo distinto por parametro" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", params: { horizon: 5_000 }, headers: headers

    expect(json["risks"].first["horizon"]).to eq(5000)
  end

  it "ignora un tramo invalido en vez de reventar" do
    get "/api/v1/vehicles/#{vehicle.id}/risks", params: { horizon: "-3" }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["risks"].first["horizon"]).to eq(1000)
  end

  it "devuelve lista vacia si el vehiculo no tiene piezas parametrizadas" do
    sin_perfil = create(:vehicle, user: user, usage_value: 10_000)

    get "/api/v1/vehicles/#{sin_perfil.id}/risks", headers: headers

    expect(json["risks"]).to eq([])
  end

  it "responde 404 si el vehiculo no existe" do
    get "/api/v1/vehicles/0/risks", headers: headers

    expect(response).to have_http_status(:not_found)
  end

  describe "aislamiento entre usuarios" do
    it "responde 404 sobre el vehiculo de otro usuario" do
      ajeno = create(:vehicle, user: create(:user))

      get "/api/v1/vehicles/#{ajeno.id}/risks", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "responde 401 sin token" do
      get "/api/v1/vehicles/#{vehicle.id}/risks"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
