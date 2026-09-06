require "rails_helper"

RSpec.describe "Api::V1::Client::ServiceRequests", type: :request do
  let(:json) { response.parsed_body }
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:vehicle) { create(:vehicle, user: user) }
  let(:attributes) do
    { serviceRequest: { vehicleId: vehicle.id, kind: "monthly_inspection",
                        address: "Calle 100 #15-20", latitude: 4.6533, longitude: -74.0836 } }
  end

  def post_request
    post "/api/v1/client/service_requests", params: attributes, as: :json, headers: headers
  end

  it "responde 401 sin token" do
    post "/api/v1/client/service_requests", params: attributes, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "el cliente pide una revision para su vehiculo" do
    expect { post_request }.to change(Services::Request, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(json).to include("kind" => "monthly_inspection", "status" => "pending")
  end

  # Una solicitud que nadie ve no le sirve a nadie.
  it "la pone frente a los talleres cercanos" do
    create(:organization, latitude: 4.6700, longitude: -74.0800)

    expect { post_request }.to change(Services::Offer, :count).by(1)
  end

  it "no la ofrece a talleres de otra ciudad" do
    create(:organization, latitude: 10.9639, longitude: -74.7964)

    expect { post_request }.not_to change(Services::Offer, :count)
  end

  it "no deja pedir para el vehiculo de otro" do
    attributes[:serviceRequest][:vehicleId] = create(:vehicle).id

    post_request

    expect(response).to have_http_status(:not_found)
  end

  it "rechaza una fecha en el pasado" do
    attributes[:serviceRequest][:scheduledFor] = 1.day.ago.iso8601

    post_request

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("scheduledFor")
  end

  it "lista solo las solicitudes de sus vehiculos" do
    create(:service_request, vehicle: vehicle, requested_by_user: user)
    create(:service_request)

    get "/api/v1/client/service_requests", headers: headers

    expect(json.length).to eq(1)
  end

  describe "cancelar" do
    it "cancela una solicitud que nadie tomo" do
      request = create(:service_request, vehicle: vehicle, requested_by_user: user)

      delete "/api/v1/client/service_requests/#{request.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(request.reload.status).to eq("canceled")
    end

    # Cancelar tiene que cerrar el trabajo y quitarle el acceso al taller.
    it "si ya la tomaron, cancela la orden y revoca el permiso" do
      request = create(:service_request, vehicle: vehicle, requested_by_user: user)
      workshop = create(:organization)
      offer = create(:service_offer, request: request, organization: workshop)
      technician = create(:membership, organization: workshop, role: "technician").user
      order = Services::OfferAcceptance.new(offer, technician).call.order

      delete "/api/v1/client/service_requests/#{request.id}", headers: headers

      expect(order.reload.status).to eq("canceled")
      expect(Garage::VehicleAccessGrant.active.where(service_order: order)).to be_empty
    end

    it "no deja cancelar la solicitud de otro" do
      delete "/api/v1/client/service_requests/#{create(:service_request).id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
