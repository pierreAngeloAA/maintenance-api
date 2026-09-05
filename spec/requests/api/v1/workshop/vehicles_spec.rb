require "rails_helper"

RSpec.describe "Api::V1::Workshop::Vehicles", type: :request do
  let(:json) { response.parsed_body }
  let(:owner) { create(:user) }
  let(:vehicle) { create(:vehicle, user: owner) }
  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:headers) do
    auth_headers_for(membership.user).merge("X-Organization-Id" => workshop.id.to_s)
  end

  describe "GET /api/v1/workshop/vehicles" do
    it "lista solo los vehiculos con permiso vigente" do
      create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)
      create(:vehicle)

      get "/api/v1/workshop/vehicles", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.map { |v| v["id"] }).to eq([ vehicle.id ])
    end

    it "no lista los que tienen el permiso revocado" do
      create(:vehicle_access_grant, :revoked, vehicle: vehicle, organization: workshop)

      get "/api/v1/workshop/vehicles", headers: headers

      expect(json).to be_empty
    end

    it "responde 403 sin contexto de organizacion" do
      get "/api/v1/workshop/vehicles", headers: auth_headers_for(membership.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/workshop/vehicles/:id" do
    it "con permiso vigente devuelve el vehiculo" do
      create(:vehicle_access_grant, :read_only, vehicle: vehicle, organization: workshop)

      get "/api/v1/workshop/vehicles/#{vehicle.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(vehicle.id)
    end

    # Responder 403 delataria que el vehiculo existe: un taller no tiene por que
    # poder averiguar que placas hay en el sistema.
    it "sin permiso responde igual que si el vehiculo no existiera" do
      get "/api/v1/workshop/vehicles/#{vehicle.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
