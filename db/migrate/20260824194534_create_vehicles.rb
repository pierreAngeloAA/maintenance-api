class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.string :vehicle_type, null: false
      t.string :make, null: false
      t.string :model, null: false
      t.integer :model_year, null: false

      # El VIN es opcional a proposito: NHTSA no cubre las motos que se venden
      # en Colombia, asi que muchos vehiculos se registran sin el.
      t.string :vin
      t.string :plate

      # El uso se guarda como valor + unidad, no como kilometraje, para poder
      # soportar despues clases de vehiculo que se miden en horas de operacion.
      t.decimal :usage_value, precision: 12, scale: 2, null: false, default: 0
      t.string :usage_unit, null: false, default: "km"

      t.string :city

      # Atributos propios de cada clase de vehiculo (cilindraje de una moto, etc.).
      t.jsonb :specs, null: false, default: {}

      t.timestamps
    end

    add_index :vehicles, :vin, unique: true, where: "vin IS NOT NULL"
    add_index :vehicles, :vehicle_type
    add_index :vehicles, :plate
  end
end
