module Reliability
  # El mismo repuesto no dura lo mismo en Bogota que en Barranquilla. Se modela
  # como vida acelerada: la vida caracteristica efectiva de la pieza es
  #
  #   eta_efectiva = eta x PI(factores que aplican)
  #
  # y el calculo de riesgo no cambia. Un factor de 0,80 dice "en este contexto la
  # pieza dura un 20% menos".
  #
  # Los factores viven en `config/context_factors.yml`, no en codigo: agregar una
  # ciudad o recalibrar un castigo es editar YAML.
  #
  # Regla de oro: un factor ausente vale 1,0. Sin ciudad, con una ciudad que no
  # conocemos o con una pieza que el contexto no afecta, el resultado es
  # exactamente el mismo que antes de existir este ajuste.
  module ContextFactors
    CATALOG_PATH = Rails.root.join("config/context_factors.yml")
    NEUTRAL = 1.0

    module_function

    def catalog
      @catalog ||= YAML.load_file(CATALOG_PATH).freeze
    end

    def cities
      @cities ||= catalog.fetch("cities").freeze
    end

    def factors
      @factors ||= catalog.fetch("factors").freeze
    end

    # Asi entra la ciudad que escribe el usuario: con tildes, mayusculas y
    # espacios de mas. Las claves del YAML ya estan en esta forma.
    def normalize(city)
      return if city.blank?

      city.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.squish
    end

    def for(vehicle)
      profile = cities[normalize(vehicle.city)]

      Context.new(terrain: profile&.fetch("terrain", nil), climate: profile&.fetch("climate", nil))
    end

    # El contexto de un vehiculo concreto, ya resuelto a terreno y clima.
    Context = Data.define(:terrain, :climate) do
      def known?
        terrain.present? || climate.present?
      end

      def life_factor_for(part_code)
        factor_for("terrain", terrain, part_code) * factor_for("climate", climate, part_code)
      end

      private

      def factor_for(dimension, value, part_code)
        return ContextFactors::NEUTRAL if value.blank?

        ContextFactors.factors.dig(dimension, value, part_code) || ContextFactors::NEUTRAL
      end
    end
  end
end
