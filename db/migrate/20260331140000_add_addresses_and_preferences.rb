class AddAddressesAndPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, foreign_key: true, null: false
      t.string :address_type, null: false, default: "delivery"
      t.string :full_name, null: false
      t.string :street, null: false
      t.string :city, null: false
      t.string :postal_code, null: false
      t.string :country, null: false, default: "FR"
      t.string :phone, null: false
      t.text :notes
      t.boolean :is_default, default: false

      t.timestamps
    end

    add_index :addresses, [ :user_id, :address_type ]
    add_index :addresses, [ :user_id, :address_type, :is_default ]

    create_table :user_preferences do |t|
      t.references :user, foreign_key: true, null: false
      t.string :language, null: false, default: "fr"
      t.boolean :notifications_email_order, default: true
      t.boolean :notifications_email_quote, default: true
      t.boolean :notifications_email_promotional, default: false

      t.timestamps
    end

    add_index :user_preferences, :user_id, unique: true unless index_exists?(:user_preferences, :user_id)
  end
end
