class CreateDiagnosticsObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostics_observations do |t|
      t.references :inspection, null: false,
        foreign_key: { to_table: :diagnostics_inspections }
      t.references :item, null: false,
        foreign_key: { to_table: :diagnostics_inspection_items }
      t.references :part_type, foreign_key: true

      # Numeros y escalas cerradas. El texto libre es solo el comentario al
      # cliente: si el tecnico escribe "llantas regulares" se pierde la
      # velocidad de desgaste, que es lo que hace valiosa la visita.
      t.decimal :numeric_value, precision: 10, scale: 2
      t.integer :scale_value
      t.boolean :boolean_value
      t.date :date_value
      t.string :severity
      t.text :notes

      t.timestamps
    end

    add_index :diagnostics_observations, [ :inspection_id, :item_id ], unique: true
    add_index :diagnostics_observations, :severity
  end
end
