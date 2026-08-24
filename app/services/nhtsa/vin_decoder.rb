module Nhtsa
  # Autocompletado de datos del vehiculo a partir del VIN, usando la API publica
  # de NHTSA (sin API key).
  #
  # Es autocompletado, NO validacion: NHTSA solo cubre vehiculos homologados en
  # EE.UU., asi que las motos y varios autos que se venden en Colombia no estan.
  # Por eso este servicio nunca levanta excepciones ni bloquea el registro: si no
  # sabe, devuelve un resultado vacio y el usuario llena los datos a mano.
  class VinDecoder
    BASE_URL = "https://vpic.nhtsa.dot.gov/api/vehicles/".freeze

    # Timeouts cortos a proposito: el usuario esta esperando frente al formulario
    # y el registro manual no puede quedar rehen de una API gringa lenta.
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 5

    # NHTSA usa su propia taxonomia. Lo que no sepamos mapear queda en blanco
    # para no preseleccionar mal la clase de vehiculo en el formulario.
    VEHICLE_TYPE_MAP = {
      "PASSENGER CAR" => "car",
      "MULTIPURPOSE PASSENGER VEHICLE (MPV)" => "car",
      "MOTORCYCLE" => "motorcycle"
    }.freeze

    Result = Data.define(:make, :model, :model_year, :vehicle_type) do
      def found?
        make.present? || model.present? || model_year.present?
      end
    end

    EMPTY_RESULT = Result.new(make: nil, model: nil, model_year: nil, vehicle_type: nil)

    def initialize(connection: nil)
      @connection = connection || build_connection
    end

    def call(vin)
      normalized_vin = normalize(vin)
      return EMPTY_RESULT if normalized_vin.blank?

      attributes = fetch(normalized_vin)
      return EMPTY_RESULT if attributes.blank?

      build_result(attributes)
    end

    private

    attr_reader :connection

    def normalize(vin)
      normalized = vin.to_s.gsub(/\s+/, "").upcase
      normalized.match?(Vehicle::VIN_FORMAT) ? normalized : nil
    end

    def fetch(vin)
      response = connection.get("DecodeVinValues/#{vin}", format: "json")
      return unless response.success?

      body = response.body
      return unless body.is_a?(Hash)

      body["Results"]&.first
    rescue Faraday::Error => e
      Rails.logger.warn("NHTSA VIN decode fallo para #{vin}: #{e.class}")
      nil
    end

    def build_result(attributes)
      Result.new(
        make: presence_of(attributes["Make"]),
        model: presence_of(attributes["Model"]),
        model_year: presence_of(attributes["ModelYear"])&.to_i,
        vehicle_type: VEHICLE_TYPE_MAP[attributes["VehicleType"]]
      )
    end

    # NHTSA devuelve cadenas vacias, no null, para lo que no conoce.
    def presence_of(value)
      value.to_s.strip.presence
    end

    def build_connection
      Faraday.new(url: BASE_URL) do |faraday|
        faraday.response :json, content_type: /\bjson$/
        faraday.options.open_timeout = OPEN_TIMEOUT
        faraday.options.timeout = READ_TIMEOUT
      end
    end
  end
end
