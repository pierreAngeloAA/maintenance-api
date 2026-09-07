require "rails_helper"

# El frontend son tres apps servidas en puertos distintos en desarrollo. Si los
# origenes no las cubren a las tres, el navegador bloquea las respuestas y la
# app falla con un error de carga que no dice nada: el API responde 200 y la
# pantalla muestra "no pudimos cargar". Por eso esto se prueba.
RSpec.describe "CORS", type: :request do
  DEV_ORIGINS = %w[
    http://localhost:4200
    http://localhost:4201
    http://localhost:4202
  ].freeze

  def preflight(origin)
    process(
      :options,
      "/api/v1/workshop/service_offers",
      headers: {
        "HTTP_ORIGIN" => origin,
        "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET",
        "HTTP_ACCESS_CONTROL_REQUEST_HEADERS" => "authorization,x-organization-id"
      }
    )
  end

  DEV_ORIGINS.each do |origin|
    it "acepta peticiones desde #{origin}" do
      preflight(origin)

      expect(response.headers["Access-Control-Allow-Origin"]).to eq(origin)
    end
  end

  it "deja pasar el header de organizacion, que es como se elige el contexto" do
    preflight("http://localhost:4201")

    expect(response.headers["Access-Control-Allow-Headers"].to_s.downcase)
      .to include("x-organization-id")
  end

  it "no le abre la puerta a cualquier origen" do
    preflight("http://evil.example.com")

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end
end
