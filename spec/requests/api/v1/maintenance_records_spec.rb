require "rails_helper"

RSpec.describe "Api::V1::MaintenanceRecords", type: :request do
  let(:json) { response.parsed_body }
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:vehicle) { create(:vehicle, :motorcycle, user: user, usage_value: 18_000) }
  let(:chain) { create(:part_type, :drive_chain) }

  describe "POST /api/v1/vehicles/:vehicle_id/maintenance_records" do
    let(:valid_attributes) do
      {
        maintenanceRecord: {
          partTypeId: chain.id,
          performedOn: "2026-07-15",
          usageAtService: 12_000,
          partBrand: "DID",
          costCents: 18_000_000,
          currency: "COP",
          notes: "Cambio con kit completo"
        }
      }
    end

    it "registra el mantenimiento y responde 201" do
      expect { post "/api/v1/vehicles/#{vehicle.id}/maintenance_records", params: valid_attributes, as: :json, headers: headers }
        .to change(MaintenanceRecord, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["partBrand"]).to eq("DID")
      expect(json["usageAtService"]).to eq("12000.0")
      expect(json["partType"]["code"]).to eq("drive_chain")
    end

    it "rechaza una pieza que no aplica a esa clase de vehiculo" do
      timing_belt = create(:part_type, :timing_belt)
      attributes = valid_attributes.deep_merge(maintenanceRecord: { partTypeId: timing_belt.id })

      post "/api/v1/vehicles/#{vehicle.id}/maintenance_records", params: attributes, as: :json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["partType"]).to be_present
    end

    it "rechaza un uso mayor al del vehiculo, con mensaje legible" do
      attributes = valid_attributes.deep_merge(maintenanceRecord: { usageAtService: 20_000 })

      post "/api/v1/vehicles/#{vehicle.id}/maintenance_records", params: attributes, as: :json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["usageAtService"].first).to be_a(String)
    end

    it "responde 404 si el vehiculo no existe" do
      post "/api/v1/vehicles/0/maintenance_records", params: valid_attributes, as: :json, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/vehicles/:vehicle_id/maintenance_records" do
    it "lista el historial, lo mas reciente primero" do
      viejo = create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 4_000, performed_on: Date.current - 200)
      nuevo = create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 15_000, performed_on: Date.current - 10)

      get "/api/v1/vehicles/#{vehicle.id}/maintenance_records", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.map { |record| record["id"] }).to eq([ nuevo.id, viejo.id ])
    end

    it "devuelve lista vacia cuando no hay historial" do
      get "/api/v1/vehicles/#{vehicle.id}/maintenance_records", headers: headers

      expect(json).to eq([])
    end

    it "no mezcla el historial de otro vehiculo" do
      otro = create(:vehicle, :motorcycle, user: user)
      create(:maintenance_record, vehicle: otro, part_type: chain, usage_at_service: 1_000)

      get "/api/v1/vehicles/#{vehicle.id}/maintenance_records", headers: headers

      expect(json).to eq([])
    end
  end

  describe "aislamiento entre usuarios" do
    it "responde 404 sobre el vehiculo de otro usuario" do
      ajeno = create(:vehicle, user: create(:user))

      get "/api/v1/vehicles/#{ajeno.id}/maintenance_records", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "responde 401 sin token" do
      get "/api/v1/vehicles/#{vehicle.id}/maintenance_records"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
