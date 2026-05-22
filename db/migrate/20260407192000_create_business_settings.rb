class CreateBusinessSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :business_settings do |t|
      t.integer :delivery_min_order_cents, null: false, default: 2000
      t.decimal :tier_one_max_km, precision: 5, scale: 2, null: false, default: 10.0
      t.integer :tier_one_fee_cents, null: false, default: 500
      t.decimal :tier_two_max_km, precision: 5, scale: 2, null: false, default: 20.0
      t.integer :tier_two_fee_cents, null: false, default: 1000
      t.decimal :vat_rate, precision: 4, scale: 3, null: false, default: 0.2

      t.timestamps
    end
  end
end
