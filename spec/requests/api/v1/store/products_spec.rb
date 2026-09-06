require "rails_helper"

RSpec.describe "Api::V1::Store::Products", type: :request do
  def json = response.parsed_body

  let(:store) { create(:organization, :store) }
  let(:membership) { create(:membership, organization: store, role: "clerk") }
  let(:headers) { auth_headers_for(membership.user).merge("X-Organization-Id" => store.id.to_s) }
  let(:part_type) { create(:part_type) }
  let(:attributes) do
    { product: { name: "Pastillas delanteras", brand: "Bosch", sku: "BP-100",
                 unitPriceCents: 12_000_000, stockQuantity: 5, status: "published",
                 partTypeId: part_type.id } }
  end

  it "responde 403 sin contexto de almacen" do
    get "/api/v1/store/products", headers: auth_headers_for(membership.user)

    expect(response).to have_http_status(:forbidden)
  end

  # Un taller no publica catalogo.
  it "responde 403 con contexto de taller" do
    workshop = create(:organization)
    m = create(:membership, user: membership.user, organization: workshop, role: "owner")

    get "/api/v1/store/products",
      headers: auth_headers_for(membership.user).merge("X-Organization-Id" => m.organization_id.to_s)

    expect(response).to have_http_status(:forbidden)
  end

  it "publica un producto" do
    expect { post "/api/v1/store/products", params: attributes, as: :json, headers: headers }
      .to change(Catalog::Product, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(json).to include("brand" => "Bosch", "available" => true, "universal" => true)
  end

  it "explica que falta si el producto no sirve" do
    post "/api/v1/store/products", params: { product: { brand: "Bosch" } },
      as: :json, headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("name")
  end

  it "lista solo los productos de su almacen" do
    create(:product, organization: store)
    create(:product)

    get "/api/v1/store/products", headers: headers

    expect(json.length).to eq(1)
  end

  it "actualiza precio y stock" do
    product = create(:product, organization: store)

    patch "/api/v1/store/products/#{product.id}",
      params: { product: { unitPriceCents: 9_000_000, stockQuantity: 0 } },
      as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json).to include("unitPriceCents" => 9_000_000, "available" => false)
  end

  it "explica que esta mal al actualizar con datos invalidos" do
    product = create(:product, organization: store)

    patch "/api/v1/store/products/#{product.id}",
      params: { product: { unitPriceCents: -1 } }, as: :json, headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("unitPriceCents")
  end

  # El catalogo de otro almacen no existe para este.
  it "no deja editar el producto de otro almacen" do
    patch "/api/v1/store/products/#{create(:product).id}",
      params: { product: { unitPriceCents: 1 } }, as: :json, headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
