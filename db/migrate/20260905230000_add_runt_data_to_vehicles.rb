class AddRuntDataToVehicles < ActiveRecord::Migration[8.1]
  def change
    # Vencimientos que solo conoce el RUNT. Valen por si solos: avisarle al
    # cliente que su SOAT vence en 23 dias no depende del motor de riesgo ni de
    # que haya talleres en la red.
    add_column :vehicles, :soat_expires_on, :date
    add_column :vehicles, :technical_inspection_expires_on, :date
    add_column :vehicles, :runt_checked_at, :datetime

    add_index :vehicles, :soat_expires_on
    add_index :vehicles, :technical_inspection_expires_on
  end
end
