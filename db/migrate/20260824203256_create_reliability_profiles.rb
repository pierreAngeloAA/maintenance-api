class CreateReliabilityProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :reliability_profiles do |t|
      t.references :part_type, null: false, foreign_key: true

      # Los parametros dependen de la clase de vehiculo: el aceite de un auto no
      # dura lo mismo que el de una moto, aunque sea la misma pieza del catalogo.
      t.string :vehicle_type, null: false

      # Forma de la curva de Weibull: beta ~1 falla aleatoria, beta > 3 desgaste.
      t.decimal :weibull_shape, precision: 6, scale: 3, null: false
      # Vida caracteristica: el uso al que ya fallo el 63,2% de las piezas.
      t.decimal :characteristic_life, precision: 12, scale: 2, null: false
      t.string :life_unit, null: false

      # De donde salio el numero. Arranca en estimacion de ingenieria y se
      # reemplaza con user_data cuando haya volumen real de mantenimientos.
      t.string :source, null: false, default: "engineering_estimate"

      t.timestamps
    end

    add_index :reliability_profiles, [ :part_type_id, :vehicle_type ], unique: true
  end
end
