module Catalog
  # Un producto que vende un almacen.
  #
  # El enlace a `part_type` es lo que ata el catalogo al resto del producto: es
  # el mismo catalogo que usan las curvas de confiabilidad, las inspecciones y
  # los mantenimientos. Sin el, el producto se vende pero no ensena nada.
  class Product < ApplicationRecord
    STATUSES = { draft: "draft", published: "published", archived: "archived" }.freeze

    # El vocabulario de unidades de uso es uno solo en todo el producto, y es el
    # mismo de `usage_value` del vehiculo: tiene que serlo para poder comparar
    # la vida util declarada contra el uso real del vehiculo.
    USAGE_UNITS = Garage::Vehicle::USAGE_UNITS.values.freeze

    belongs_to :organization, class_name: "Identity::Organization"
    belongs_to :part_type, optional: true

    has_many :fitments, dependent: :destroy

    enum :status, STATUSES, validate: true, prefix: true

    before_validation :drop_usage_units_without_a_value

    normalizes :sku, with: ->(sku) { sku.strip.upcase.presence }
    normalizes :brand, with: ->(brand) { brand.strip }

    validates :name, :brand, presence: true
    validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :sku, uniqueness: { scope: :organization_id }, allow_nil: true
    validates :expected_life_usage_unit, :warranty_usage_unit,
      inclusion: { in: USAGE_UNITS }, allow_nil: true
    validates :expected_life_usage_value, :expected_life_months,
      :warranty_usage_value, :warranty_months,
      numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validate :organization_is_a_store
    validate :usage_values_declare_their_unit

    scope :published, -> { where(status: "published") }
    scope :in_stock, -> { where(stock_quantity: 1..) }

    # Lo que un cliente puede comprar hoy.
    scope :available, -> { published.in_stock }

    # La busqueda del mostrador: el taller escribe "bosch" y espera que algo
    # aparezca. ILIKE sobre nombre y marca alcanza para el tamano de catalogo de
    # hoy; el dia que no alcance entra un indice de texto completo, no un LIKE
    # mas grande. El termino se escapa: un "%" suelto no puede volverse comodin.
    scope :search, ->(term) {
      pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"

      where("name ILIKE :term OR brand ILIKE :term", term: pattern)
    }

    # Los productos que sirven para un vehiculo: los que declaran compatibilidad
    # con el, mas los universales. Un producto sin ningun fitment es universal
    # (aceite, liquido de frenos), no un producto incompleto.
    scope :for_vehicle, ->(vehicle) {
      where(id: Fitment.matching(vehicle).select(:product_id))
        .or(where.not(id: Fitment.select(:product_id)))
    }

    def universal?
      fitments.empty?
    end

    def available?
      status_published? && stock_quantity.positive?
    end

    # Cuanto dura la pieza: 40.000 km, 24 meses, o los dos.
    def expected_life?
      expected_life_months.present? || expected_life_usage_value.present?
    end

    # Que respalda el almacen si falla antes. La convencion del sector es "lo
    # primero que ocurra": 12 meses o 20.000 km. No hay booleano `has_warranty`
    # porque una garantia sin meses ni kilometros es un dato vacio, y el
    # booleano se desincroniza el dia que alguien borre los meses.
    def warranty?
      warranty_months.present? || warranty_usage_value.present?
    end

    private

    def organization_is_a_store
      return if organization.nil? || organization.store?

      errors.add(:organization, :inclusion)
    end

    # Una unidad sin valor es basura, no un error del que la manda: se limpia.
    def drop_usage_units_without_a_value
      self.expected_life_usage_unit = nil if expected_life_usage_value.blank?
      self.warranty_usage_unit = nil if warranty_usage_value.blank?
    end

    # Al reves si es un error: 40.000 sin unidad puede ser kilometros u horas de
    # motor, y quien lo lea despues tendria que adivinar.
    def usage_values_declare_their_unit
      if expected_life_usage_value.present? && expected_life_usage_unit.blank?
        errors.add(:expected_life_usage_unit, :blank)
      end

      return if warranty_usage_value.blank? || warranty_usage_unit.present?

      errors.add(:warranty_usage_unit, :blank)
    end
  end
end
