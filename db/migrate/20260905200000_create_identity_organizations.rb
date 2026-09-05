class CreateIdentityOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :identity_organizations do |t|
      t.string :kind, null: false
      t.string :name, null: false
      t.string :nit
      t.string :city
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.string :status, null: false, default: "pending"
      t.datetime :verified_at

      t.timestamps
    end

    add_index :identity_organizations, :kind
    add_index :identity_organizations, :status
    add_index :identity_organizations, :nit, unique: true, where: "nit IS NOT NULL"
  end
end
