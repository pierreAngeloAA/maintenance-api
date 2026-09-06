require "rails_helper"

RSpec.describe "Api::V1::Workshop::Orders", type: :request do
  def json = response.parsed_body

  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:headers) do
    auth_headers_for(membership.user).merge("X-Organization-Id" => workshop.id.to_s)
  end
  let(:product) { create(:product, stock_quantity: 5, unit_price_cents: 10_000) }

  # La orden queda a nombre del taller, no de la persona que la hizo.
  it "el taller compra repuestos y la orden queda a su nombre" do
    post "/api/v1/workshop/orders",
      params: { order: { items: [ { productId: product.id, quantity: 2 } ] } },
      as: :json, headers: headers

    expect(response).to have_http_status(:created)
    expect(json).to include("buyerType" => "Identity::Organization", "buyerId" => workshop.id)
  end

  it "lista las compras del taller, no las personales del tecnico" do
    Orders::Placement.new(buyer: workshop, lines: [ { product_id: product.id, quantity: 1 } ]).call
    Orders::Placement.new(buyer: membership.user,
      lines: [ { product_id: product.id, quantity: 1 } ]).call

    get "/api/v1/workshop/orders", headers: headers

    expect(json.length).to eq(1)
  end

  it "responde 403 sin contexto de taller" do
    get "/api/v1/workshop/orders", headers: auth_headers_for(membership.user)

    expect(response).to have_http_status(:forbidden)
  end
end
