require "rails_helper"

RSpec.describe "Api::V1::Store::Fitments", type: :request do
  def json = response.parsed_body

  let(:store) { create(:organization, :store) }
  let(:membership) { create(:membership, organization: store, role: "clerk") }
  let(:headers) { auth_headers_for(membership.user).merge("X-Organization-Id" => store.id.to_s) }
  let(:product) { create(:product, organization: store) }

  it "declara para que vehiculos sirve el producto" do
    post "/api/v1/store/products/#{product.id}/fitments",
      params: { fitment: { vehicleType: "car", make: "Renault", model: "Logan",
                           yearFrom: 2015, yearTo: 2020 } },
      as: :json, headers: headers

    expect(response).to have_http_status(:created)
    expect(json).to include("make" => "Renault", "yearFrom" => 2015)
  end

  # Compatibilidad gruesa: toda la marca, sin enumerar lineas.
  it "acepta compatibilidad sin linea, que significa toda la marca" do
    post "/api/v1/store/products/#{product.id}/fitments",
      params: { fitment: { vehicleType: "motorcycle", make: "AKT" } },
      as: :json, headers: headers

    expect(response).to have_http_status(:created)
    expect(json["model"]).to be_nil
  end

  it "rechaza un rango de anos al reves" do
    post "/api/v1/store/products/#{product.id}/fitments",
      params: { fitment: { vehicleType: "car", yearFrom: 2020, yearTo: 2015 } },
      as: :json, headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to have_key("yearTo")
  end

  it "lista las compatibilidades del producto" do
    create(:fitment, product: product)

    get "/api/v1/store/products/#{product.id}/fitments", headers: headers

    expect(json.length).to eq(1)
  end

  it "quita una compatibilidad" do
    fitment = create(:fitment, product: product)

    delete "/api/v1/store/products/#{product.id}/fitments/#{fitment.id}", headers: headers

    expect(response).to have_http_status(:no_content)
    expect(Catalog::Fitment.exists?(fitment.id)).to be(false)
  end

  it "no deja tocar el producto de otro almacen" do
    get "/api/v1/store/products/#{create(:product).id}/fitments", headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
