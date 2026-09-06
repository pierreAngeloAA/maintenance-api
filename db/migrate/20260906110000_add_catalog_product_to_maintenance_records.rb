class AddCatalogProductToMaintenanceRecords < ActiveRecord::Migration[8.1]
  def change
    # Opcional: un mantenimiento hecho con un repuesto comprado por fuera de la
    # app sigue siendo valido, con part_brand en texto libre.
    #
    # on_delete: :nullify a proposito. El historial de un vehiculo no puede
    # depender de que un almacen siga vendiendo algo: si el producto desaparece,
    # el registro sobrevive con la marca que quedo guardada en part_brand.
    add_reference :maintenance_records, :catalog_product,
      foreign_key: { to_table: :catalog_products, on_delete: :nullify }
  end
end
