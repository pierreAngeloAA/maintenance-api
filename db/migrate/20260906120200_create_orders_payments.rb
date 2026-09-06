class CreateOrdersPayments < ActiveRecord::Migration[8.1]
  def change
    # Tabla delgada a proposito: cada almacen aliado es el comercio ante la
    # pasarela, asi que el dinero va directo del cliente al almacen y la
    # plataforma nunca lo toca. Aca solo se registra la referencia del pago.
    create_table :orders_payments do |t|
      t.references :order, null: false, foreign_key: { to_table: :orders_orders }

      t.string :gateway, null: false
      t.string :gateway_ref
      t.string :status, null: false, default: "pending"
      t.integer :amount_cents, null: false

      t.timestamps
    end

    add_index :orders_payments, [ :gateway, :gateway_ref ], unique: true,
      where: "gateway_ref IS NOT NULL"
  end
end
