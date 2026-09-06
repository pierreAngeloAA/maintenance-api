class CreateCatalogProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_products do |t|
      t.references :organization,
        null: false, foreign_key: { to_table: :identity_organizations }
      # Opcional: hay productos que no mapean a ninguna pieza del catalogo
      # (accesorios, consumibles). Sin esto, el producto no alimenta el modelo.
      t.references :part_type, foreign_key: true

      t.string :name, null: false
      t.string :brand, null: false
      t.string :sku
      t.text :description
      t.integer :unit_price_cents, null: false
      t.string :currency, null: false, default: "COP"
      t.integer :stock_quantity, null: false, default: 0
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    # El SKU es unico dentro del almacen, no globalmente: dos almacenes pueden
    # usar el mismo codigo para cosas distintas.
    add_index :catalog_products, [ :organization_id, :sku ],
      unique: true, where: "sku IS NOT NULL"
    add_index :catalog_products, [ :organization_id, :status ]
    add_index :catalog_products, :brand
  end
end
