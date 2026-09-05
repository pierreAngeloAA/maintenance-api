module Runt
  # Consulta al RUNT a traves de PlacApi.
  #
  # El RUNT no expone API publica: la consulta ciudadana es web con captcha y el
  # acceso directo va por convenio. PlacApi es un revendedor que cobra por
  # consulta, sin mensualidad.
  #
  # Igual que NHTSA, esto es **enriquecimiento oportunista y nunca un
  # requisito**: si PlacApi no conoce la placa, esta caida, se quedo sin creditos
  # o no hay API key configurada, se devuelve un resultado vacio y no se rompe
  # ningun flujo. Por eso no levanta excepciones.
  class PlacapiClient
    BASE_URL = "https://placapi.com/api/".freeze

    # A diferencia de NHTSA, aca el timeout es largo a proposito: la primera
    # consulta de una placa tarda 30-90 segundos y despues queda cacheada del
    # lado de PlacApi. Por eso esto solo puede correr en background.
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 120

    Result = Data.define(
      :make, :line, :model_year, :displacement_cc, :fuel, :vehicle_class,
      :engine_number, :chassis_number, :vin,
      :soat_expires_on, :technical_inspection_expires_on
    ) do
      def found?
        make.present? || line.present? || vin.present?
      end
    end

    EMPTY_RESULT = Result.new(**Result.members.index_with { nil })

    def initialize(connection: nil)
      @connection = connection
    end

    def call(plate)
      normalized = normalize(plate)
      return EMPTY_RESULT if normalized.blank? || api_key.blank?

      data = fetch(normalized)
      return EMPTY_RESULT if data.blank?

      build_result(data)
    end

    private

    def api_key
      ENV["PLACAPI_API_KEY"]
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |faraday|
        faraday.options.open_timeout = OPEN_TIMEOUT
        faraday.options.timeout = READ_TIMEOUT
        faraday.response :json
      end
    end

    def fetch(plate)
      response = connection.get("consulta", { placa: plate }, { "x-api-key" => api_key })
      return unless response.success?

      response.body.is_a?(Hash) ? response.body["data"] : nil
    rescue Faraday::Error
      # Caida, timeout o DNS: no es asunto del usuario que esta registrando.
      nil
    end

    def normalize(plate)
      plate.to_s.gsub(/\s+/, "").upcase.presence
    end

    def build_result(data)
      Result.new(
        make: data["marca"].presence,
        line: data["linea"].presence,
        model_year: data["modelo"].presence&.to_i,
        displacement_cc: data["cilindraje"].presence&.to_i,
        fuel: data["combustible"].presence,
        vehicle_class: data["clase"].presence,
        engine_number: data["motor"].presence,
        chassis_number: data["chasis"].presence,
        vin: data["vin"].presence,
        soat_expires_on: expiry(data["soat"]),
        technical_inspection_expires_on: expiry(data["tecnomecanica"])
      )
    end

    def expiry(document)
      return unless document.is_a?(Hash)

      Date.parse(document["fecha_vencimiento"].to_s)
    rescue Date::Error
      # Una fecha ilegible no invalida el resto de la consulta.
      nil
    end
  end
end
