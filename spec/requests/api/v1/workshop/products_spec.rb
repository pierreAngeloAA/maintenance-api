require "rails_helper"

RSpec.describe "Api::V1::Workshop::Products", type: :request do
  let(:json) { response.parsed_body }
  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:headers) do
    auth_headers_for(membership.user).merge("X-Organization-Id" => workshop.id.to_s)
  end

  def ids = json.map { |product| product["id"] }

  describe "GET /api/v1/workshop/products" do
    it "muestra el catalogo disponible de cualquier almacen" do
      product = create(:product)

      get "/api/v1/workshop/products", headers: headers

      expect(response).to have_http_status(:ok)
      expect(ids).to include(product.id)
    end

    # Lo que el almacen no publico todavia no existe para el taller.
    it "no muestra borradores ni productos agotados" do
      draft = create(:product, :draft)
      empty = create(:product, :out_of_stock)

      get "/api/v1/workshop/products", headers: headers

      expect(ids).not_to include(draft.id, empty.id)
    end

    it "ordena por precio, del mas barato al mas caro" do
      caro = create(:product, unit_price_cents: 90_000_00)
      barato = create(:product, unit_price_cents: 10_000_00)

      get "/api/v1/workshop/products", headers: headers

      expect(ids).to eq([ barato.id, caro.id ])
    end

    it "responde 403 sin contexto de taller" do
      get "/api/v1/workshop/products", headers: auth_headers_for(membership.user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "filtros" do
    it "filtra por tipo de pieza" do
      pastillas = create(:product)
      create(:product)

      get "/api/v1/workshop/products",
        params: { partTypeId: pastillas.part_type_id }, headers: headers

      expect(ids).to eq([ pastillas.id ])
    end

    # El taller escribe "bosch" en el mostrador y espera que algo aparezca.
    it "busca por nombre y por marca" do
      bosch = create(:product, brand: "Bosch")
      create(:product, brand: "Gates")

      get "/api/v1/workshop/products", params: { q: "bosc" }, headers: headers

      expect(ids).to eq([ bosch.id ])
    end

    it "ignora un filtro de busqueda vacio" do
      product = create(:product)

      get "/api/v1/workshop/products", params: { q: "  " }, headers: headers

      expect(ids).to include(product.id)
    end

    it "no se rompe con un termino que trae comodines de SQL" do
      create(:product, brand: "Bosch")

      get "/api/v1/workshop/products", params: { q: "%" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json).to be_empty
    end
  end

  # El taller compra para un trabajo, muchas veces para un vehiculo que no esta
  # registrado en la plataforma. Por eso el vehiculo es un filtro opcional y no
  # la ruta: colgar la vitrina de un `vehicle_id` lo obligaria a inventarse un
  # vehiculo para poder comprar aceite.
  describe "filtro por vehiculo" do
    let(:owner) { create(:user) }
    let(:logan) do
      create(:vehicle, user: owner, make: "Renault", model: "Logan", model_year: 2019)
    end

    it "con permiso vigente devuelve los compatibles y los universales" do
      create(:vehicle_access_grant, vehicle: logan, organization: workshop)
      compatible = create(:fitment).product
      universal = create(:product)
      incompatible = create(:fitment, make: "Mazda").product

      get "/api/v1/workshop/products",
        params: { vehicleId: logan.id }, headers: headers

      expect(ids).to include(compatible.id, universal.id)
      expect(ids).not_to include(incompatible.id)
    end

    # Contestar 403 delataria que el vehiculo existe. Un taller no tiene por que
    # poder averiguar que placas hay en el sistema.
    it "sin permiso vigente responde 404 y no el catalogo completo" do
      create(:product)

      get "/api/v1/workshop/products",
        params: { vehicleId: logan.id }, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "con el permiso revocado responde 404" do
      create(:vehicle_access_grant, :revoked, vehicle: logan, organization: workshop)

      get "/api/v1/workshop/products",
        params: { vehicleId: logan.id }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
