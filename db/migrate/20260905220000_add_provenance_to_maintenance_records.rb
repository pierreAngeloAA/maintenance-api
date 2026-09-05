class AddProvenanceToMaintenanceRecords < ActiveRecord::Migration[8.1]
  def change
    # Los registros que ya existen los escribio el dueno: no habia otra forma.
    add_column :maintenance_records, :source, :string, null: false, default: "owner"
    add_reference :maintenance_records, :recorded_by_user, foreign_key: { to_table: :users }
    add_reference :maintenance_records, :recorded_by_organization,
      foreign_key: { to_table: :identity_organizations }

    add_index :maintenance_records, :source
  end
end
