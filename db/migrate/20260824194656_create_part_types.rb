class CreatePartTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :part_types do |t|
      # Identificador estable en ingles, usado por el codigo y por los seeds.
      t.string :code, null: false
      # Nombre visible para el usuario: va en espanol porque es contenido, no codigo.
      t.string :name, null: false
      t.string :category, null: false

      # Que clases de vehiculo llevan esta pieza. Guardarlo como arreglo evita
      # una columna booleana por tipo y deja entrar clases nuevas sin migrar.
      t.string :applicable_vehicle_types, array: true, null: false, default: []

      t.timestamps
    end

    add_index :part_types, :code, unique: true
    add_index :part_types, :category
    add_index :part_types, :applicable_vehicle_types, using: :gin
  end
end
