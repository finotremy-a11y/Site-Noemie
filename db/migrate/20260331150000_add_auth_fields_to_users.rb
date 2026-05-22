class AddAuthFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # Authentification par mot de passe (bcrypt)
    add_column :users, :password_digest, :string

    # Champs profil distincts (first_name / last_name plutôt que full_name)
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
  end
end
