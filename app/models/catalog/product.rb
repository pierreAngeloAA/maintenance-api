module Catalog
  # Un producto que vende un almacen.
  #
  # El enlace a `part_type` es lo que ata el catalogo al resto del producto: es
  # el mismo catalogo que usan las curvas de confiabilidad, las inspecciones y
  # los mantenimientos. Sin el, el producto se vende pero no ensena nada.
  class Product < ApplicationRecord
    STATUSES = { draft: "draft", published: "published", archived: "archived" }.freeze

    belongs_to :organization, class_name: "Identity::Organization"
    belongs_to :part_type, optional: true

    has_many :fitments, dependent: :destroy

    enum :status, STATUSES, validate: true, prefix: true

    normalizes :sku, with: ->(sku) { sku.strip.upcase.presence }
    normalizes :brand, with: ->(brand) { brand.strip }

    validates :name, :brand, presence: true
    validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :sku, uniqueness: { scope: :organization_id }, allow_nil: true
    validate :organization_is_a_store

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

    private

    def organization_is_a_store
      return if organization.nil? || organization.store?

      errors.add(:organization, :inclusion)
    end
  end
end
