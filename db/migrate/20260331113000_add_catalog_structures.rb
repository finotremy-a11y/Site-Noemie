class AddCatalogStructures < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :categories, :slug, unique: true
    add_index :categories, :position

    change_table :products, bulk: true do |t|
      t.references :category, null: false, foreign_key: true
      t.jsonb :badges, null: false, default: []
      t.date :seasonal_start_date
      t.date :seasonal_end_date
    end
    add_index :products, :badges, using: :gin

    create_table :product_price_changes do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :old_price_cents, null: false
      t.integer :new_price_cents, null: false
      t.string :reason
      t.string :changed_by
      t.timestamps
    end
  end
end
