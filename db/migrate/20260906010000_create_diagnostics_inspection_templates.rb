class CreateDiagnosticsInspectionTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostics_inspection_templates do |t|
      t.string :code, null: false
      t.integer :version, null: false
      t.string :vehicle_type, null: false
      t.datetime :published_at

      t.timestamps
    end

    # El checklist va a cambiar, y las mediciones viejas tienen que seguir siendo
    # comparables: por eso se versiona en vez de editarse en sitio.
    add_index :diagnostics_inspection_templates, [ :code, :version ], unique: true
    add_index :diagnostics_inspection_templates, [ :vehicle_type, :published_at ]
  end
end
