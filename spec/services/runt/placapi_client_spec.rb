require "rails_helper"

RSpec.describe Runt::PlacapiClient do
  subject(:client) { described_class.new }

  let(:url) { "#{described_class::BASE_URL}consulta?placa=ABC123" }

  def stub_placapi(status:, body:)
    stub_request(:get, url).to_return(
      status: status, body: body.to_json, headers: { "Content-Type" => "application/json" }
    )
  end

  around do |example|
    original = ENV["PLACAPI_API_KEY"]
    ENV["PLACAPI_API_KEY"] = "clave-de-prueba"
    example.run
    ENV["PLACAPI_API_KEY"] = original
  end

  it "devuelve los datos del vehiculo" do
    stub_placapi(status: 200, body: { data: {
      marca: "BAJAJ", linea: "PULSAR NS 200", modelo: "2021", cilindraje: "199",
      combustible: "GASOLINA", clase: "MOTOCICLETA", motor: "M123", chasis: "C456",
      vin: "9FBLSRB56KM123456",
      soat: { fecha_vencimiento: "2027-03-15" },
      tecnomecanica: { fecha_vencimiento: "2027-01-20" }
    } })

    result = client.call("ABC123")

    expect(result).to be_found
    expect(result).to have_attributes(
      make: "BAJAJ", line: "PULSAR NS 200", model_year: 2021, displacement_cc: 199,
      soat_expires_on: Date.new(2027, 3, 15),
      technical_inspection_expires_on: Date.new(2027, 1, 20)
    )
  end

  it "manda la API key en el header que espera PlacApi" do
    stub_placapi(status: 200, body: { data: { marca: "AKT" } })

    client.call("ABC123")

    expect(a_request(:get, url).with(headers: { "x-api-key" => "clave-de-prueba" })).to have_been_made
  end

  it "normaliza la placa" do
    stub_placapi(status: 200, body: { data: { marca: "AKT" } })

    client.call(" abc 123 ")

    expect(a_request(:get, url)).to have_been_made
  end

  # Que el RUNT no conozca una placa no es un error: el registro manual manda.
  it "devuelve vacio si PlacApi no conoce la placa" do
    stub_placapi(status: 404, body: { error: "no encontrado" })

    expect(client.call("ABC123")).not_to be_found
  end

  it "devuelve vacio si la respuesta viene sin datos" do
    stub_placapi(status: 200, body: { data: {} })

    expect(client.call("ABC123")).not_to be_found
  end

  it "devuelve vacio si PlacApi esta caida" do
    stub_request(:get, url).to_return(status: 500, body: "")

    expect(client.call("ABC123")).not_to be_found
  end

  it "devuelve vacio si PlacApi se queda sin creditos" do
    stub_placapi(status: 402, body: { error: "sin creditos" })

    expect(client.call("ABC123")).not_to be_found
  end

  it "devuelve vacio si la conexion falla" do
    stub_request(:get, url).to_timeout

    expect(client.call("ABC123")).not_to be_found
  end

  it "no consulta con una placa vacia" do
    expect(client.call("")).not_to be_found
    expect(a_request(:get, url)).not_to have_been_made
  end

  it "ignora una fecha de vencimiento que no se puede leer" do
    stub_placapi(status: 200, body: { data: {
      marca: "AKT", soat: { fecha_vencimiento: "pendiente" }
    } })

    expect(client.call("ABC123").soat_expires_on).to be_nil
  end

  context "sin API key configurada" do
    around do |example|
      original = ENV["PLACAPI_API_KEY"]
      ENV.delete("PLACAPI_API_KEY")
      example.run
      ENV["PLACAPI_API_KEY"] = original
    end

    # Sin clave el enriquecimiento simplemente no ocurre: nada se rompe.
    it "no consulta nada" do
      expect(client.call("ABC123")).not_to be_found
      expect(a_request(:get, url)).not_to have_been_made
    end
  end
end
