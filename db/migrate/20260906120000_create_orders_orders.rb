class CreateOrdersOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders_orders do |t|
      # Polimorfico: un taller comprando pastillas para un trabajo y un cliente
      # comprandolas para su carro son la misma operacion con distinto
      # comprador. Sin esto habria que duplicar todo el flujo.
      t.references :buyer, null: false, polymorphic: true
      t.references :seller_organization,
        null: false, foreign_key: { to_table: :identity_organizations }

      t.string :status, null: false, default: "pending"
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "COP"
      t.string :address
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.datetime :placed_at, null: false

      t.timestamps
    end

    add_index :orders_orders, :status
    add_index :orders_orders, [ :seller_organization_id, :status ]
  end
end
