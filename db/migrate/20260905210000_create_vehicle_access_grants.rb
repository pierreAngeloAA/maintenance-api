class CreateVehicleAccessGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_access_grants do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :organization,
        null: false, foreign_key: { to_table: :identity_organizations }
      # Quien lo otorgo: siempre el dueno del vehiculo, y queda registrado.
      t.references :granted_by, null: false, foreign_key: { to_table: :users }

      t.string :access_level, null: false
      t.datetime :granted_at, null: false
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end

    # Un solo permiso vigente por vehiculo y organizacion. Parcial, porque
    # revocado uno se puede volver a otorgar: es temporal, no una lista negra.
    add_index :vehicle_access_grants, [ :vehicle_id, :organization_id ],
      unique: true, where: "revoked_at IS NULL",
      name: "index_vehicle_access_grants_vigentes"
    add_index :vehicle_access_grants, :expires_at
  end
end
