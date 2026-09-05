require "rails_helper"

RSpec.describe "Api::V1::Client::Vehicles", type: :request do
  let(:json) { response.parsed_body }
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "POST /api/v1/vehicles" do
    let(:valid_attributes) do
      {
        vehicle: {
          vehicleType: "car",
          make: "Renault",
          model: "Logan",
          modelYear: 2019,
          vin: "5YJ3E1EA6PF384836",
          plate: "abc123",
          usageValue: 45_000,
          usageUnit: "km",
          city: "Bogota"
        }
      }
    end

    it "crea el vehiculo y responde 201" do
      expect { post "/api/v1/client/vehicles", params: valid_attributes, as: :json, headers: headers }
        .to change(Garage::Vehicle, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "devuelve el vehiculo creado en camelCase" do
      post "/api/v1/client/vehicles", params: valid_attributes, as: :json, headers: headers

      expect(json["id"]).to be_present
      expect(json["vehicleType"]).to eq("car")
      expect(json["modelYear"]).to eq(2019)
      expect(json["usageValue"]).to eq("45000.0")
      expect(json["usageUnit"]).to eq("km")
    end

    it "normaliza la placa" do
      post "/api/v1/client/vehicles", params: valid_attributes, as: :json, headers: headers

      expect(json["plate"]).to eq("ABC123")
    end

    it "registra una moto sin VIN: es el caso normal en Colombia" do
      attributes = {
        vehicle: {
          vehicleType: "motorcycle",
          make: "AKT",
          model: "NKD 125",
          modelYear: 2021,
          usageValue: 12_000,
          usageUnit: "km",
          city: "Medellin"
        }
      }

      post "/api/v1/client/vehicles", params: attributes, as: :json, headers: headers

      expect(response).to have_http_status(:created)
      expect(json["vin"]).to be_nil
    end

    it "responde 422 con los errores cuando los datos no sirven" do
      attributes = valid_attributes.deep_merge(vehicle: { make: "", vin: "NOTAVIN" })

      post "/api/v1/client/vehicles", params: attributes, as: :json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["make"]).to be_present
      expect(json["errors"]["vin"]).to be_present
    end

    it "devuelve las llaves de error en camelCase" do
      attributes = valid_attributes.deep_merge(vehicle: { modelYear: 1800 })

      post "/api/v1/client/vehicles", params: attributes, as: :json, headers: headers

      expect(json["errors"]).to have_key("modelYear")
    end

    it "ignora atributos que no estan permitidos" do
      attributes = valid_attributes.deep_merge(vehicle: { id: 99_999 })

      post "/api/v1/client/vehicles", params: attributes, as: :json, headers: headers

      expect(json["id"]).not_to eq(99_999)
    end
  end

  describe "GET /api/v1/vehicles" do
    it "lista los vehiculos, el mas reciente primero" do
      older = create(:vehicle, user: user, created_at: 2.days.ago)
      newer = create(:vehicle, :motorcycle, user: user, created_at: 1.hour.ago)

      get "/api/v1/client/vehicles", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.map { |vehicle| vehicle["id"] }).to eq([ newer.id, older.id ])
    end

    it "devuelve una lista vacia cuando no hay vehiculos" do
      get "/api/v1/client/vehicles", headers: headers

      expect(json).to eq([])
    end
  end

  describe "aislamiento entre usuarios" do
    it "no lista los vehiculos de otro usuario" do
      create(:vehicle, user: create(:user))

      get "/api/v1/client/vehicles", headers: headers

      expect(json).to eq([])
    end

    it "responde 404 al pedir el vehiculo de otro usuario, sin revelar que existe" do
      ajeno = create(:vehicle, user: create(:user))

      get "/api/v1/client/vehicles/#{ajeno.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "responde 401 sin token" do
      get "/api/v1/client/vehicles"

      expect(response).to have_http_status(:unauthorized)
    end

    it "el vehiculo creado queda a nombre del usuario de la sesion" do
      attributes = {
        vehicle: {
          vehicleType: "car", make: "Renault", model: "Logan",
          modelYear: 2019, usageValue: 45_000, usageUnit: "km"
        }
      }

      post "/api/v1/client/vehicles", params: attributes, as: :json, headers: headers

      expect(Garage::Vehicle.find(json["id"]).user).to eq(user)
    end
  end

  describe "GET /api/v1/vehicles/:id" do
    it "devuelve el vehiculo" do
      vehicle = create(:vehicle, user: user)

      get "/api/v1/client/vehicles/#{vehicle.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(vehicle.id)
    end

    it "incluye las piezas del catalogo que aplican al vehiculo" do
      create(:part_type, :drive_chain)
      create(:part_type, :timing_belt)
      motorcycle = create(:vehicle, :motorcycle, user: user)

      get "/api/v1/client/vehicles/#{motorcycle.id}", headers: headers

      codes = json["partTypes"].map { |part_type| part_type["code"] }
      expect(codes).to contain_exactly("drive_chain")
    end

    it "responde 404 cuando el vehiculo no existe" do
      get "/api/v1/client/vehicles/0", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to be_present
    end
  end
end
