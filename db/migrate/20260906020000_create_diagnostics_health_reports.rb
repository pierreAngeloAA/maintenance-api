class CreateDiagnosticsHealthReports < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostics_health_reports do |t|
      t.references :vehicle, null: false, foreign_key: true
      # Primer dia del mes que cubre.
      t.date :period, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :generated_at, null: false

      t.timestamps
    end

    # Un reporte por vehiculo y mes: volver a generarlo lo actualiza, no duplica.
    add_index :diagnostics_health_reports, [ :vehicle_id, :period ], unique: true
  end
end
