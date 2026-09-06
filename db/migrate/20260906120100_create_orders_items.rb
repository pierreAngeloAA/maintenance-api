class CreateOrdersItems < ActiveRecord::Migration[8.1]
  def change
    create_table :orders_items do |t|
      t.references :order, null: false, foreign_key: { to_table: :orders_orders }
      # nullify: si el almacen borra el producto, la orden vieja sobrevive con
      # lo que se vendio. Por eso el nombre, la marca y el SKU se copian.
      t.references :product,
        foreign_key: { to_table: :catalog_products, on_delete: :nullify }

      t.string :product_name, null: false
      t.string :product_brand, null: false
      t.string :product_sku
      t.integer :quantity, null: false
      # Congelado al momento de la orden: si el almacen sube el precio manana,
      # la orden vieja no cambia.
      t.integer :unit_price_cents, null: false

      t.timestamps
    end
  end
end
