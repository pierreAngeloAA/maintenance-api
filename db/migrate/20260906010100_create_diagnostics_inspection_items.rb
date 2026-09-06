class CreateDiagnosticsInspectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostics_inspection_items do |t|
      t.references :template, null: false,
        foreign_key: { to_table: :diagnostics_inspection_templates }
      t.references :part_type, foreign_key: true

      t.string :code, null: false
      t.string :label, null: false
      t.string :phase, null: false
      t.string :value_type, null: false
      t.string :unit
      t.decimal :minimum, precision: 10, scale: 2
      t.decimal :maximum, precision: 10, scale: 2
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :diagnostics_inspection_items, [ :template_id, :code ], unique: true
    add_index :diagnostics_inspection_items, [ :template_id, :phase, :position ],
      name: "index_inspection_items_on_template_phase_position"
  end
end
