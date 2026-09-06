require "rails_helper"

RSpec.describe "Api::V1::Workshop::ServiceOffers", type: :request do
  let(:json) { response.parsed_body }
  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:headers) do
    auth_headers_for(membership.user).merge("X-Organization-Id" => workshop.id.to_s)
  end
  let(:offer) { create(:service_offer, organization: workshop) }

  it "responde 403 sin contexto de taller" do
    get "/api/v1/workshop/service_offers", headers: auth_headers_for(membership.user)

    expect(response).to have_http_status(:forbidden)
  end

  it "lista las ofertas vigentes del taller" do
    offer
    create(:service_offer, organization: create(:organization))

    get "/api/v1/workshop/service_offers", headers: headers

    expect(json.length).to eq(1)
    expect(json.first["request"]).to include("kind" => "monthly_inspection")
  end

  it "no lista las vencidas" do
    create(:service_offer, :expired, organization: workshop)

    get "/api/v1/workshop/service_offers", headers: headers

    expect(json).to be_empty
  end

  # Antes de tomarlo solo se ve lo minimo para decidir: ni placa ni dueno.
  it "no expone el vehiculo completo antes de tomar el servicio" do
    offer

    get "/api/v1/workshop/service_offers", headers: headers

    expect(json.first["vehicle"]).to include("make")
    expect(json.first["vehicle"]).not_to have_key("plate")
  end

  describe "tomar el servicio" do
    it "crea la orden y devuelve 201" do
      patch "/api/v1/workshop/service_offers/#{offer.id}", headers: headers

      expect(response).to have_http_status(:created)
      expect(json["status"]).to eq("assigned")
    end

    it "el taller queda con permiso sobre el vehiculo" do
      patch "/api/v1/workshop/service_offers/#{offer.id}", headers: headers

      get "/api/v1/workshop/vehicles", headers: headers
      expect(json.map { |v| v["id"] }).to eq([ offer.request.vehicle_id ])
    end

    it "una oferta vencida responde 422" do
      vencida = create(:service_offer, :expired, organization: workshop)

      patch "/api/v1/workshop/service_offers/#{vencida.id}", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("offer_not_open")
    end

    it "no deja tomar la oferta de otro taller" do
      ajena = create(:service_offer, organization: create(:organization))

      patch "/api/v1/workshop/service_offers/#{ajena.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "pasar de largo" do
    it "el taller rechaza la oferta y deja de verla" do
      delete "/api/v1/workshop/service_offers/#{offer.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(offer.reload.status).to eq("rejected")

      get "/api/v1/workshop/service_offers", headers: headers
      expect(json).to be_empty
    end
  end
end
