module Garage
  # Un mantenimiento que el usuario ya hizo: que pieza cambio, cuando y con cuanto
  # uso encima.
  #
  # Esta tabla es la data que genera la ventaja competitiva del producto: no existe
  # en ninguna API externa, y es la que alimenta el modelo de riesgo (el uso desde
  # el ultimo cambio de cada pieza).
  class MaintenanceRecord < ApplicationRecord
    # De donde salio el dato. Un registro hecho por un taller verificado vale
    # mas para el modelo de riesgo que uno que el dueno escribio de memoria seis
    # meses despues, y el dia que se recalibren los reliability_profiles con la
    # flota real va a hacer falta poder ponderarlos distinto. Si no se guarda
    # desde el principio, esa informacion no se recupera.
    SOURCES = { owner: "owner", workshop: "workshop" }.freeze

    belongs_to :vehicle
    belongs_to :part_type
    belongs_to :recorded_by_user, class_name: "User", optional: true
    belongs_to :recorded_by_organization,
      class_name: "Identity::Organization", optional: true

    # El repuesto concreto que se instalo, cuando salio del catalogo de la app.
    # Es lo que convierte "DID", "did" y "D.I.D." en la misma marca y permite
    # preguntar cuanto duro *esa* marca, en *esa* ciudad, en *ese* vehiculo.
    belongs_to :catalog_product, class_name: "Catalog::Product", optional: true

    enum :source, SOURCES, validate: true, prefix: true

    # La procedencia se fija al crear y no se reescribe despues.
    before_validation :record_provenance, on: :create

    # La marca se copia del producto, no se referencia: si el almacen borra el
    # producto manana, el historial del vehiculo tiene que sobrevivir.
    before_validation :copy_brand_from_product

    validate :product_matches_part_type

    scope :from_catalog, -> { where.not(catalog_product_id: nil) }

    validates :performed_on, presence: true
    validates :usage_at_service, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cost_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    validate :performed_on_is_not_in_the_future
    validate :usage_at_service_within_vehicle_usage
    validate :part_type_applies_to_vehicle

    # El ultimo mantenimiento de cada pieza, que es el que define el uso acumulado
    # desde el cambio.
    scope :latest_per_part_type, -> {
      select("DISTINCT ON (part_type_id) maintenance_records.*")
        .order(:part_type_id, usage_at_service: :desc, performed_on: :desc)
    }

    private

    def record_provenance
      self.recorded_by_user ||= Current.user
      self.recorded_by_organization ||= Current.organization
      self.source = recorded_by_organization ? "workshop" : "owner"
    end

    def copy_brand_from_product
      return if catalog_product.nil?

      self.part_brand = catalog_product.brand
    end

    # Registrar unas pastillas como si fueran una cadena ensuciaria justo el
    # dato que hace valioso este enlace.
    def product_matches_part_type
      return if catalog_product.nil? || catalog_product.part_type_id.nil?
      return if catalog_product.part_type_id == part_type_id

      errors.add(:catalog_product, :inclusion)
    end

    def performed_on_is_not_in_the_future
      return if performed_on.blank?
      return if performed_on <= Date.current

      # El count no es decorativo: sin el, el mensaje revienta al renderizar el 422.
      errors.add(:performed_on, :less_than_or_equal_to, count: Date.current)
    end

    def usage_at_service_within_vehicle_usage
      return if usage_at_service.blank? || vehicle.blank? || vehicle.usage_value.blank?
      return if usage_at_service <= vehicle.usage_value

      errors.add(:usage_at_service, :less_than_or_equal_to, count: vehicle.usage_value)
    end

    # No se le cambia la cadena a un auto.
    def part_type_applies_to_vehicle
      return if part_type.blank? || vehicle.blank?
      return if part_type.applicable_vehicle_types.include?(vehicle.vehicle_type)

      errors.add(:part_type, :inclusion)
    end
  end
end
