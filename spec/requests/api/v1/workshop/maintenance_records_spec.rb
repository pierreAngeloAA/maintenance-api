require "rails_helper"

RSpec.describe "Api::V1::Workshop::MaintenanceRecords", type: :request do
  let(:json) { response.parsed_body }
  let(:owner) { create(:user) }
  let(:vehicle) { create(:vehicle, user: owner, usage_value: 50_000) }
  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:headers) do
    auth_headers_for(membership.user).merge("X-Organization-Id" => workshop.id.to_s)
  end
  let(:part_type) { create(:part_type, applicable_vehicle_types: [ vehicle.vehicle_type ]) }
  let(:attributes) do
    { maintenanceRecord: { partTypeId: part_type.id, performedOn: Date.current.to_s,
                           usageAtService: 45_000, partBrand: "Bosch" } }
  end

  def post_record
    post "/api/v1/workshop/vehicles/#{vehicle.id}/maintenance_records",
      params: attributes, as: :json, headers: headers
  end

  it "un taller con permiso de escritura registra a nombre del cliente" do
    create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)

    expect { post_record }.to change(Garage::MaintenanceRecord, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it "un taller con permiso de solo lectura no puede escribir" do
    create(:vehicle_access_grant, :read_only, vehicle: vehicle, organization: workshop)

    expect { post_record }.not_to change(Garage::MaintenanceRecord, :count)
    expect(response).to have_http_status(:forbidden)
  end

  # La consulta decide la existencia y la politica el nivel: un permiso vencido
  # ya no esta vigente, asi que el vehiculo no existe para este taller.
  it "un taller con el permiso vencido ya no lo ve" do
    create(:vehicle_access_grant, :expired, vehicle: vehicle, organization: workshop)

    post_record

    expect(response).to have_http_status(:not_found)
  end

  it "sin ningun permiso no distingue el vehiculo de uno inexistente" do
    post_record

    expect(response).to have_http_status(:not_found)
  end

  it "con permiso de lectura puede ver el historial" do
    create(:vehicle_access_grant, :read_only, vehicle: vehicle, organization: workshop)
    create(:maintenance_record, vehicle: vehicle, part_type: part_type)

    get "/api/v1/workshop/vehicles/#{vehicle.id}/maintenance_records", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json.length).to eq(1)
  end

  it "explica que esta mal si el registro no sirve" do
    create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)
    attributes[:maintenanceRecord][:usageAtService] = 999_999

    post_record

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("usageAtService")
  end
end
