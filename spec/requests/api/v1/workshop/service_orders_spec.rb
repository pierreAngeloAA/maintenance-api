require "rails_helper"

RSpec.describe "Api::V1::Workshop::ServiceOrders", type: :request do
  let(:json) { response.parsed_body }
  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:technician) { membership.user }
  let(:headers) { auth_headers_for(technician).merge("X-Organization-Id" => workshop.id.to_s) }
  let(:offer) { create(:service_offer, organization: workshop) }
  let(:order) { Services::OfferAcceptance.new(offer, technician).call.order }

  def move_to(status, as: headers)
    patch "/api/v1/workshop/service_orders/#{order.id}",
      params: { status: status }, as: :json, headers: as
  end

  it "lista los trabajos del taller" do
    order

    get "/api/v1/workshop/service_orders", headers: headers

    expect(json.length).to eq(1)
  end

  it "el tecnico marca que va en camino" do
    move_to("en_route")

    expect(response).to have_http_status(:ok)
    expect(order.reload.status).to eq("en_route")
  end

  it "una transicion invalida responde 422" do
    move_to("completed")

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["error"]).to eq("invalid_transition")
  end

  # El trabajo es de quien lo tomo: otro tecnico del mismo taller no lo mueve.
  it "otro tecnico del taller no puede moverlo" do
    otro = create(:membership, organization: workshop, role: "technician").user

    move_to("en_route", as: auth_headers_for(otro).merge("X-Organization-Id" => workshop.id.to_s))

    expect(response).to have_http_status(:forbidden)
  end

  it "al completar se revoca el permiso sobre el vehiculo" do
    move_to("in_progress")
    move_to("completed")

    get "/api/v1/workshop/vehicles", headers: headers
    expect(json).to be_empty
  end
end
