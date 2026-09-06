require "rails_helper"

RSpec.describe "Api::V1::Workshop::Inspections", type: :request do
  # Metodo y no `let`: este spec hace varias peticiones por ejemplo y un `let`
  # memoizaria la primera respuesta.
  def json = response.parsed_body

  let(:workshop) { create(:organization) }
  let(:membership) { create(:membership, organization: workshop, role: "technician") }
  let(:technician) { membership.user }
  let(:headers) { auth_headers_for(technician).merge("X-Organization-Id" => workshop.id.to_s) }
  let(:vehicle) { create(:vehicle, usage_value: 50_000) }

  before do
    PartTypeCatalog.load!
    InspectionTemplateCatalog.load!
    create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)
  end

  def open_inspection
    post "/api/v1/workshop/inspections",
      params: { inspection: { vehicleId: vehicle.id, usageValue: 50_000 } },
      as: :json, headers: headers
  end

  describe "abrir la visita" do
    it "trae los campos de la plantilla vigente, ordenados por fase" do
      open_inspection

      expect(response).to have_http_status(:created)
      expect(json["items"].first["phase"]).to eq("engine_off")
      expect(json["items"].map { |i| i["phase"] }.uniq)
        .to eq(%w[engine_off engine_idle driving])
    end

    it "los campos de medida traen su unidad" do
      open_inspection

      labrado = json["items"].find { |i| i["code"] == "tire_tread_fl" }
      expect(labrado).to include("valueType" => "numeric", "unit" => "mm")
    end

    # Si se le cierra la app a mitad de la visita, al volver sigue ahi.
    it "retoma la que ya tenia abierta en vez de empezar otra" do
      open_inspection
      primera = json["id"]

      expect { open_inspection }.not_to change(Diagnostics::Inspection, :count)
      expect(json["id"]).to eq(primera)
    end

    it "sin permiso sobre el vehiculo responde 404" do
      ajeno = create(:vehicle)

      post "/api/v1/workshop/inspections",
        params: { inspection: { vehicleId: ajeno.id, usageValue: 10 } },
        as: :json, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    # Una clase de vehiculo sin checklist publicado todavia.
    it "avisa si no hay plantilla para esa clase de vehiculo" do
      Diagnostics::InspectionTemplate.where(vehicle_type: "motorcycle").destroy_all
      moto = create(:vehicle, :motorcycle)
      create(:vehicle_access_grant, vehicle: moto, organization: workshop)

      post "/api/v1/workshop/inspections",
        params: { inspection: { vehicleId: moto.id, usageValue: 10 } },
        as: :json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("no_template")
    end

    it "responde 403 sin contexto de taller" do
      post "/api/v1/workshop/inspections",
        params: { inspection: { vehicleId: vehicle.id, usageValue: 10 } },
        as: :json, headers: auth_headers_for(technician)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "medir" do
    let(:inspection) do
      open_inspection
      Diagnostics::Inspection.find(json["id"])
    end
    let(:item) { inspection.template.items.find_by(code: "tire_tread_fl") }

    def measure(**values)
      post "/api/v1/workshop/inspections/#{inspection.id}/observations",
        params: { observation: { itemId: item.id, **values } }, as: :json, headers: headers
    end

    it "guarda la medicion en milimetros" do
      measure(numericValue: 4.5, severity: "watch")

      expect(response).to have_http_status(:created)
      expect(json).to include("value" => "4.5", "severity" => "watch")
    end

    # Se guardan una por una a medida que avanza, no todas al final.
    it "corregir una medicion no crea otra" do
      measure(numericValue: 4.5)

      expect { measure(numericValue: 3.0) }.not_to change(Diagnostics::Observation, :count)
    end

    it "rechaza una medicion fuera del rango del campo" do
      measure(numericValue: 99)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("numericValue")
    end

    it "rechaza dejar el valor vacio" do
      measure(notes: "regulares")

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "cerrar la visita" do
    let(:inspection) do
      open_inspection
      Diagnostics::Inspection.find(json["id"])
    end

    def close(**params)
      patch "/api/v1/workshop/inspections/#{inspection.id}",
        params: { inspection: { latitude: 4.6533, longitude: -74.0836 }, **params },
        headers: headers
    end

    # Un campo de medida, no el primero del checklist: ese es una escala y un
    # valor numerico ahi no es valido.
    def measure_something
      item = inspection.template.items.find_by(code: "tire_tread_fl")

      post "/api/v1/workshop/inspections/#{inspection.id}/observations",
        params: { observation: { itemId: item.id, numericValue: 4.5 } },
        as: :json, headers: headers
    end

    def photo
      Rack::Test::UploadedFile.new(
        StringIO.new("foto"), "image/jpeg", original_filename: "llanta.jpg"
      )
    end

    it "se cierra con foto, ubicacion y mediciones" do
      measure_something

      close(photos: [ photo ])

      expect(response).to have_http_status(:ok)
      expect(json["status"]).to eq("completed")
      expect(json["durationSeconds"]).to be_present
    end

    it "no se cierra sin foto" do
      measure_something

      close

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("photos")
    end

    it "no se cierra sin ninguna medicion" do
      close(photos: [ photo ])

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("observations")
    end
  end

  describe "consultar una visita" do
    it "muestra los campos con los que se hizo, no los de la version actual" do
      open_inspection
      id = json["id"]

      get "/api/v1/workshop/inspections/#{id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["items"]).to be_present
    end

    it "no deja ver la visita de otro taller" do
      ajena = create(:inspection)

      get "/api/v1/workshop/inspections/#{ajena.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
