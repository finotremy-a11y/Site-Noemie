class CreateCoreBusinessTables < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :full_name
      t.string :phone
      t.string :role, null: false, default: "customer"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "EUR"
      t.boolean :active, null: false, default: true
      t.integer :stock_quantity, null: false, default: 0
      t.string :image_url
      t.timestamps
    end

    create_table :product_options do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_delta_cents, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :carts do |t|
      t.references :user, foreign_key: true
      t.string :session_token
      t.string :status, null: false, default: "open"
      t.timestamps
    end
    add_index :carts, :session_token

    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.jsonb :options, null: false, default: {}
      t.timestamps
    end

    create_table :orders do |t|
      t.references :user, foreign_key: true
      t.string :order_number, null: false
      t.string :status, null: false, default: "draft"
      t.string :payment_status, null: false, default: "pending"
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :delivery_fee_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :service_mode, null: false, default: "pickup"
      t.datetime :requested_at
      t.string :customer_email
      t.string :customer_phone
      t.text :delivery_address
      t.timestamps
    end
    add_index :orders, :order_number, unique: true

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.string :name, null: false
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.integer :line_total_cents, null: false
      t.jsonb :options, null: false, default: {}
      t.timestamps
    end

    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :provider, null: false, default: "stripe"
      t.string :provider_payment_id
      t.string :status, null: false, default: "pending"
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "EUR"
      t.string :idempotency_key
      t.datetime :paid_at
      t.timestamps
    end
    add_index :payments, :provider_payment_id
    add_index :payments, :idempotency_key

    create_table :payment_events do |t|
      t.references :payment, foreign_key: true
      t.string :provider_event_id
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at
      t.timestamps
    end
    add_index :payment_events, :provider_event_id, unique: true

    create_table :reviews do |t|
      t.references :user, foreign_key: true
      t.references :order, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    create_table :quotes do |t|
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.string :phone
      t.string :event_type
      t.integer :guest_count
      t.datetime :event_date
      t.text :message
      t.string :status, null: false, default: "new"
      t.timestamps
    end

    create_table :invoices do |t|
      t.references :order, foreign_key: true
      t.string :invoice_number, null: false
      t.integer :total_cents, null: false
      t.string :status, null: false, default: "issued"
      t.datetime :issued_at
      t.timestamps
    end
    add_index :invoices, :invoice_number, unique: true

    create_table :audit_logs do |t|
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :resource_type, null: false
      t.bigint :resource_id
      t.string :request_id
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :audit_logs, [ :resource_type, :resource_id ]
    add_index :audit_logs, :request_id
  end
end
