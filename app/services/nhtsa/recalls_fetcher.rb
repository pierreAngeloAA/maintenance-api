module Nhtsa
  # Recalls de seguridad activos de un vehiculo, desde la API publica de NHTSA.
  #
  # Igual que el decoder: NHTSA solo cubre vehiculos homologados en EE.UU., asi
  # que para buena parte del parque colombiano la respuesta va a ser vacia. Eso
  # no es un error, y la interfaz tiene que decirlo con claridad.
  class RecallsFetcher
    BASE_URL = "https://api.nhtsa.gov/".freeze
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 5

    # Los recalls no cambian de un dia para otro.
    CACHE_TTL = 1.day

    # NHTSA manda las fechas como MM/DD/AAAA.
    REPORT_DATE_FORMAT = "%m/%d/%Y".freeze

    Recall = Data.define(
      :campaign_number,
      :manufacturer,
      :component,
      :summary,
      :consequence,
      :remedy,
      :reported_on,
      :park_it,
      :park_outside
    )

    def initialize(connection: nil)
      @connection = connection || build_connection
    end

    def call(make:, model:, model_year:)
      return [] if make.blank? || model.blank? || model_year.blank?

      results = cached_results(make.to_s.downcase.strip, model.to_s.downcase.strip, model_year.to_i)

      Array(results).map { |result| build_recall(result) }
    end

    private

    attr_reader :connection

    def cached_results(make, model, model_year)
      key = [ "nhtsa/recalls", make, model, model_year ].join("/")

      cached = Rails.cache.read(key)
      return cached if cached

      results = fetch(make, model, model_year)
      # Una respuesta fallida no se cachea: se reintenta en la proxima consulta.
      Rails.cache.write(key, results, expires_in: CACHE_TTL) unless results.nil?

      results
    end

    def fetch(make, model, model_year)
      response = connection.get("recalls/recallsByVehicle", make: make, model: model, modelYear: model_year)
      return unless response.success?

      body = response.body
      return unless body.is_a?(Hash)

      Array(body["results"])
    rescue Faraday::Error => e
      Rails.logger.warn("NHTSA recalls fallo para #{make} #{model} #{model_year}: #{e.class}")
      nil
    end

    def build_recall(result)
      Recall.new(
        campaign_number: result["NHTSACampaignNumber"],
        manufacturer: result["Manufacturer"],
        component: result["Component"],
        summary: result["Summary"],
        consequence: result["Consequence"],
        remedy: result["Remedy"],
        reported_on: parse_date(result["ReportReceivedDate"]),
        park_it: result["parkIt"] || false,
        park_outside: result["parkOutSide"] || false
      )
    end

    def parse_date(value)
      Date.strptime(value.to_s, REPORT_DATE_FORMAT)
    rescue Date::Error
      nil
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
