class CreateServicesOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :services_offers do |t|
      t.references :request, null: false, foreign_key: { to_table: :services_requests }
      t.references :organization,
        null: false, foreign_key: { to_table: :identity_organizations }
      # Se llena al aceptar: la oferta es del taller, la toma una persona.
      t.references :technician_user, foreign_key: { to_table: :users }

      t.string :status, null: false, default: "offered"
      t.integer :price_cents
      t.datetime :expires_at

      t.timestamps
    end

    # Una sola oferta por solicitud y taller.
    add_index :services_offers, [ :request_id, :organization_id ], unique: true
    add_index :services_offers, :status
  end
end
