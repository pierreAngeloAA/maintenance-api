class CreateUsersAndSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name

      t.timestamps
    end

    add_index :users, :email, unique: true

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true

      # Guardamos el digest, no el token: si alguien lee la base de datos no se
      # queda con sesiones utilizables.
      t.string :token_digest, null: false

      t.timestamps
    end

    add_index :sessions, :token_digest, unique: true

    # Cada vehiculo pertenece a un usuario. Sin datos en produccion todavia,
    # asi que se puede crear directamente como obligatorio.
    add_reference :vehicles, :user, null: false, foreign_key: true
  end
end
