class CreateDiagnosticsInspections < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostics_inspections do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :template, null: false,
        foreign_key: { to_table: :diagnostics_inspection_templates }
      t.references :technician_user, null: false, foreign_key: { to_table: :users }
      t.references :organization,
        null: false, foreign_key: { to_table: :identity_organizations }
      t.references :service_order, foreign_key: { to_table: :services_orders }

      t.string :status, null: false, default: "in_progress"
      # Sin el kilometraje del momento, una medicion en mm no significa nada.
      t.decimal :usage_value, precision: 12, scale: 2, null: false
      t.datetime :started_at, null: false
      t.datetime :performed_at
      t.integer :duration_seconds
      # Prueba de que la visita ocurrio: se remunera, asi que tiene que ser auditable.
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.text :summary

      t.timestamps
    end

    add_index :diagnostics_inspections, [ :vehicle_id, :performed_at ]
    add_index :diagnostics_inspections, :status
  end
end
