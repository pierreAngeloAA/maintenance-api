require "rails_helper"

RSpec.describe "Api::V1::Client::Orders", type: :request do
  def json = response.parsed_body

  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:store) { create(:organization, :store) }
  let(:product) do
    create(:product, organization: store, unit_price_cents: 10_000, stock_quantity: 5)
  end

  def buy(quantity: 2)
    post "/api/v1/client/orders",
      params: { order: { address: "Calle 100 #15-20",
                         items: [ { productId: product.id, quantity: quantity } ] } },
      as: :json, headers: headers
  end

  it "responde 401 sin token" do
    post "/api/v1/client/orders", params: { order: { items: [] } }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "el cliente compra repuestos" do
    expect { buy }.to change(Orders::Order, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(json).to include("status" => "pending", "totalCents" => 20_000)
    expect(json["items"].first).to include("quantity" => 2)
  end

  it "no deja pedir mas de lo que hay" do
    buy(quantity: 99)

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["error"]).to eq("out_of_stock")
  end

  it "lista solo sus ordenes" do
    buy
    Orders::Placement.new(buyer: create(:user), lines: [ { product_id: product.id, quantity: 1 } ]).call

    get "/api/v1/client/orders", headers: headers

    expect(json.length).to eq(1)
  end

  it "no deja ver la orden de otro" do
    otra = Orders::Placement.new(
      buyer: create(:user), lines: [ { product_id: product.id, quantity: 1 } ]
    ).call.order

    get "/api/v1/client/orders/#{otra.id}", headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it "muestra el detalle de su propia orden" do
    buy
    id = json["id"]

    get "/api/v1/client/orders/#{id}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["items"].first).to include("productBrand" => "Bosch")
  end

  it "muestra quien vende" do
    buy

    expect(json["sellerOrganization"]).to include("name" => store.name)
  end
end
