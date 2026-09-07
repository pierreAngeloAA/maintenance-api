class AddLifespanAndWarrantyToCatalogProducts < ActiveRecord::Migration[8.1]
  def change
    # Cuanto dura la pieza y que respalda el almacen si falla antes. Son cosas
    # distintas y no se deducen una de la otra: un amortiguador puede durar
    # 60.000 km y tener 12 meses de garantia.
    #
    # El uso va como valor + unidad, igual que `usage_value` del vehiculo: la
    # vida util de una pieza de un bote se mide en horas de motor, y comparar
    # esto contra el historial de mantenimientos dependeria de adivinar la
    # unidad si la columna fuera "kilometros".
    change_table :catalog_products, bulk: true do |t|
      t.integer :expected_life_usage_value
      t.string :expected_life_usage_unit
      t.integer :expected_life_months

      t.integer :warranty_usage_value
      t.string :warranty_usage_unit
      t.integer :warranty_months
    end
  end
end
