class AddServiceOrderToVehicleAccessGrants < ActiveRecord::Migration[8.1]
  def change
    # Se dejo fuera en #34 porque la tabla no existia todavia. El permiso que
    # nace de un servicio queda amarrado a el, y muere con el.
    add_reference :vehicle_access_grants, :service_order,
      foreign_key: { to_table: :services_orders }
  end
end
