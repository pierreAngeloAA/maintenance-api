class CreateServicesRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :services_requests do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :requested_by_user, null: false, foreign_key: { to_table: :users }

      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :scheduled_for
      t.string :address
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.text :notes

      t.timestamps
    end

    add_index :services_requests, :status
    add_index :services_requests, :kind
  end
end
