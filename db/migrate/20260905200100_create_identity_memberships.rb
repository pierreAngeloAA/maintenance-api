class CreateIdentityMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :identity_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization,
        null: false, foreign_key: { to_table: :identity_organizations }
      t.string :role, null: false
      t.datetime :invited_at
      t.datetime :accepted_at

      t.timestamps
    end

    # Una sola membresia por persona y organizacion: el rol vive en la relacion.
    add_index :identity_memberships, [ :user_id, :organization_id ], unique: true
    add_index :identity_memberships, :accepted_at
  end
end
