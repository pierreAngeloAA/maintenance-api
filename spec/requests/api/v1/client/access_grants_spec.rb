require "rails_helper"

# El vehiculo y su historial son del cliente: tiene que poder ver quien tiene
# acceso y quitarlo cuando quiera.
RSpec.describe "Api::V1::Client::AccessGrants", type: :request do
  let(:json) { response.parsed_body }
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:vehicle) { create(:vehicle, user: user) }
  let(:workshop) { create(:organization, name: "Taller El Rayo") }

  describe "GET" do
    it "muestra que organizaciones tienen acceso y con que alcance" do
      create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)

      get "/api/v1/client/vehicles/#{vehicle.id}/access_grants", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.first).to include(
        "accessLevel" => "write",
        "organization" => hash_including("name" => "Taller El Rayo")
      )
    end

    it "no muestra los ya revocados" do
      create(:vehicle_access_grant, :revoked, vehicle: vehicle, organization: workshop)

      get "/api/v1/client/vehicles/#{vehicle.id}/access_grants", headers: headers

      expect(json).to be_empty
    end

    it "no deja ver los permisos del vehiculo de otro" do
      get "/api/v1/client/vehicles/#{create(:vehicle).id}/access_grants", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST" do
    it "el cliente le da acceso a un taller" do
      post "/api/v1/client/vehicles/#{vehicle.id}/access_grants",
        params: { accessGrant: { organizationId: workshop.id, accessLevel: "write" } },
        as: :json, headers: headers

      expect(response).to have_http_status(:created)
      expect(Garage::VehicleAccessGrant.last).to have_attributes(
        organization_id: workshop.id, access_level: "write", granted_by_id: user.id
      )
    end

    it "rechaza un alcance que no existe" do
      post "/api/v1/client/vehicles/#{vehicle.id}/access_grants",
        params: { accessGrant: { organizationId: workshop.id, accessLevel: "todo" } },
        as: :json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE" do
    it "revocar deja al taller sin acceso" do
      grant = create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)

      delete "/api/v1/client/vehicles/#{vehicle.id}/access_grants/#{grant.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(grant.reload.revoked_at).to be_present
      expect(Garage::VehicleAccessGrant.active).not_to include(grant)
    end

    it "no deja revocar permisos del vehiculo de otro" do
      grant = create(:vehicle_access_grant)

      delete "/api/v1/client/vehicles/#{grant.vehicle_id}/access_grants/#{grant.id}",
        headers: headers

      expect(response).to have_http_status(:not_found)
      expect(grant.reload.revoked_at).to be_nil
    end
  end
end
