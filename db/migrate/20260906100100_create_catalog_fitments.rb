class CreateCatalogFitments < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_fitments do |t|
      t.references :product, null: false,
        foreign_key: { to_table: :catalog_products }

      t.string :vehicle_type, null: false
      # make y model nulos significan "cualquiera": permite declarar
      # compatibilidad gruesa sin enumerar todas las lineas.
      t.string :make
      t.string :model
      t.integer :year_from
      t.integer :year_to

      t.timestamps
    end

    add_index :catalog_fitments, [ :product_id, :vehicle_type ]
    add_index :catalog_fitments, [ :vehicle_type, :make, :model ]
  end
end
