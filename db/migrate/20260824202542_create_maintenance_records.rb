class CreateMaintenanceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_records do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :part_type, null: false, foreign_key: true

      t.date :performed_on, null: false

      # Uso del vehiculo al momento del mantenimiento, en la unidad del vehiculo.
      # De aca sale el "t" de la curva de riesgo: uso desde el ultimo cambio.
      t.decimal :usage_at_service, precision: 12, scale: 2, null: false

      # Marca del repuesto: entra al modelo de riesgo cuando haya volumen de datos.
      t.string :part_brand

      t.integer :cost_cents
      t.string :currency, null: false, default: "COP"
      t.text :notes

      t.timestamps
    end

    # El calculo de riesgo siempre busca el ultimo mantenimiento de cada pieza.
    add_index :maintenance_records, [ :vehicle_id, :part_type_id, :usage_at_service ],
      name: "index_maintenance_records_on_vehicle_part_and_usage"
  end
end
