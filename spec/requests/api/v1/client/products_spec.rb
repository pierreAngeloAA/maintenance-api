require "rails_helper"

RSpec.describe "Api::V1::Client::Products", type: :request do
  def json = response.parsed_body

  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:logan) do
    create(:vehicle, user: user, make: "Renault", model: "Logan", model_year: 2019)
  end

  def get_products
    get "/api/v1/client/vehicles/#{logan.id}/products", headers: headers
  end

  it "muestra los repuestos compatibles" do
    compatible = create(:fitment).product

    get_products

    expect(response).to have_http_status(:ok)
    expect(json.map { |p| p["id"] }).to include(compatible.id)
  end

  it "no muestra los incompatibles" do
    incompatible = create(:fitment, make: "Mazda").product

    get_products

    expect(json.map { |p| p["id"] }).not_to include(incompatible.id)
  end

  # Aceite, liquido de frenos: sirven para todo.
  it "muestra los universales y los marca como tales" do
    universal = create(:product)

    get_products

    expect(json.find { |p| p["id"] == universal.id }).to include("universal" => true)
  end

  it "no muestra borradores ni productos sin stock" do
    create(:product, :draft)
    create(:product, :out_of_stock)

    get_products

    expect(json).to be_empty
  end

  it "ordena del mas barato al mas caro" do
    create(:product, unit_price_cents: 20_000_000)
    create(:product, unit_price_cents: 5_000_000)

    get_products

    expect(json.map { |p| p["unitPriceCents"] }).to eq([ 5_000_000, 20_000_000 ])
  end

  it "no deja buscar para el vehiculo de otro" do
    get "/api/v1/client/vehicles/#{create(:vehicle).id}/products", headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
