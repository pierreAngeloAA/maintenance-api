class CreateServicesOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :services_orders do |t|
      # Unico: una solicitud se convierte en una sola orden. Es lo que impide
      # que dos tecnicos tomen el mismo servicio, a nivel de base de datos y no
      # de confianza en el codigo.
      t.references :request,
        null: false, foreign_key: { to_table: :services_requests }, index: { unique: true }
      t.references :organization,
        null: false, foreign_key: { to_table: :identity_organizations }
      t.references :technician_user, null: false, foreign_key: { to_table: :users }

      t.string :status, null: false, default: "assigned"
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :total_cents

      t.timestamps
    end

    add_index :services_orders, :status
  end
end
