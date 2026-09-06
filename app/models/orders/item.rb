module Orders
  # Una linea de la orden.
  #
  # El nombre, la marca, el SKU y el precio se COPIAN del producto al momento de
  # comprar. Referenciar el producto vivo es el error clasico: el almacen sube
  # el precio o corrige el nombre y la factura de hace tres meses cambia sola.
  class Item < ApplicationRecord
    belongs_to :order
    belongs_to :product, class_name: "Catalog::Product", optional: true

    validates :product_name, :product_brand, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than: 0 }
    validates :unit_price_cents,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def total_cents
      quantity * unit_price_cents
    end
  end
end
