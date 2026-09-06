require "rails_helper"

RSpec.describe "Api::V1::Store::Orders", type: :request do
  def json = response.parsed_body

  let(:store) { create(:organization, :store) }
  let(:membership) { create(:membership, organization: store, role: "clerk") }
  let(:headers) { auth_headers_for(membership.user).merge("X-Organization-Id" => store.id.to_s) }
  let(:product) { create(:product, organization: store, stock_quantity: 5) }
  let(:order) do
    Orders::Placement.new(buyer: create(:user),
      lines: [ { product_id: product.id, quantity: 1 } ]).call.order
  end

  def move_to(status)
    patch "/api/v1/store/orders/#{order.id}",
      params: { status: status }, as: :json, headers: headers
  end

  it "responde 403 sin contexto de almacen" do
    get "/api/v1/store/orders", headers: auth_headers_for(membership.user)

    expect(response).to have_http_status(:forbidden)
  end

  it "lista solo sus ventas" do
    order
    otro = create(:product)
    Orders::Placement.new(buyer: create(:user),
      lines: [ { product_id: otro.id, quantity: 1 } ]).call

    get "/api/v1/store/orders", headers: headers

    expect(json.length).to eq(1)
  end

  it "marca la venta como pagada" do
    move_to("paid")

    expect(response).to have_http_status(:ok)
    expect(order.reload.status).to eq("paid")
  end

  # Con la opcion A el dinero va directo del cliente al almacen: aca solo queda
  # la referencia para conciliar.
  it "registra la referencia de la pasarela al marcar pagada" do
    patch "/api/v1/store/orders/#{order.id}",
      params: { status: "paid", payment: { gateway: "wompi", gatewayRef: "TX-123" } },
      as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["payments"].first).to include(
      "gateway" => "wompi", "gatewayRef" => "TX-123", "status" => "approved",
      "amountCents" => order.total_cents
    )
  end

  it "se puede marcar pagada sin referencia, si se cobro por fuera" do
    move_to("paid")

    expect(response).to have_http_status(:ok)
    expect(json["payments"]).to be_empty
  end

  it "no acepta dos veces la misma referencia de la pasarela" do
    patch "/api/v1/store/orders/#{order.id}",
      params: { status: "paid", payment: { gateway: "wompi", gatewayRef: "TX-123" } },
      as: :json, headers: headers

    otro = create(:product, organization: store, stock_quantity: 3)
    otra = Orders::Placement.new(buyer: create(:user),
      lines: [ { product_id: otro.id, quantity: 1 } ]).call.order

    patch "/api/v1/store/orders/#{otra.id}",
      params: { status: "paid", payment: { gateway: "wompi", gatewayRef: "TX-123" } },
      as: :json, headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("gatewayRef")
    expect(otra.reload.status).to eq("pending")
  end

  it "no deja saltar de pendiente a entregada" do
    move_to("delivered")

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["error"]).to eq("invalid_transition")
  end

  it "no deja revivir una entregada" do
    move_to("paid"); move_to("shipped"); move_to("delivered")

    move_to("shipped")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "no deja tocar la venta de otro almacen" do
    otro = create(:product)
    ajena = Orders::Placement.new(buyer: create(:user),
      lines: [ { product_id: otro.id, quantity: 1 } ]).call.order

    patch "/api/v1/store/orders/#{ajena.id}", params: { status: "paid" },
      as: :json, headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
