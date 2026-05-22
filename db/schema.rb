# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_10_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "address_type", default: "delivery", null: false
    t.string "city", null: false
    t.string "country", default: "FR", null: false
    t.datetime "created_at", null: false
    t.string "full_name", null: false
    t.boolean "is_default", default: false
    t.text "notes"
    t.string "phone", null: false
    t.string "postal_code", null: false
    t.string "street", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "address_type", "is_default"], name: "index_addresses_on_user_id_and_address_type_and_is_default"
    t.index ["user_id", "address_type"], name: "index_addresses_on_user_id_and_address_type"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "request_id"
    t.bigint "resource_id"
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["request_id"], name: "index_audit_logs_on_request_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "business_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delivery_min_order_cents", default: 2000, null: false
    t.integer "tier_one_fee_cents", default: 500, null: false
    t.decimal "tier_one_max_km", precision: 5, scale: 2, default: "10.0", null: false
    t.integer "tier_two_fee_cents", default: 1000, null: false
    t.decimal "tier_two_max_km", precision: 5, scale: 2, default: "20.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "vat_rate", precision: 4, scale: 3, default: "0.2", null: false
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "options", default: {}, null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_token"
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["session_token"], name: "index_carts_on_session_token"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "contact_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contact_requests_on_created_at"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "invoice_number", null: false
    t.datetime "issued_at"
    t.bigint "order_id"
    t.string "pdf_url"
    t.string "status", default: "issued", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["order_id"], name: "index_invoices_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "line_total_cents", null: false
    t.string "name", null: false
    t.jsonb "options", default: {}, null: false
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_phone"
    t.text "delivery_address"
    t.integer "delivery_fee_cents", default: 0, null: false
    t.string "order_number", null: false
    t.string "payment_status", default: "pending", null: false
    t.datetime "requested_at"
    t.string "service_mode", default: "pickup", null: false
    t.string "status", default: "draft", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.datetime "occurred_at"
    t.jsonb "payload", default: {}, null: false
    t.bigint "payment_id"
    t.string "provider_event_id"
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_payment_events_on_payment_id"
    t.index ["provider_event_id"], name: "index_payment_events_on_provider_event_id", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "idempotency_key"
    t.bigint "order_id", null: false
    t.datetime "paid_at"
    t.string "provider", default: "stripe", null: false
    t.string "provider_payment_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["provider", "idempotency_key"], name: "idx_payments_provider_idempotency_key_unique", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index ["provider_payment_id"], name: "index_payments_on_provider_payment_id"
  end

  create_table "product_options", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "price_delta_cents", default: 0, null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_options_on_product_id"
  end

  create_table "product_price_changes", force: :cascade do |t|
    t.string "changed_by"
    t.datetime "created_at", null: false
    t.integer "new_price_cents", null: false
    t.integer "old_price_cents", null: false
    t.bigint "product_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_price_changes_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "badges", default: [], null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.text "description"
    t.string "image_url"
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.date "seasonal_end_date"
    t.date "seasonal_start_date"
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["badges"], name: "index_products_on_badges", using: :gin
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.integer "budget_cents"
    t.text "constraints"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "event_date"
    t.string "event_type"
    t.integer "guest_count"
    t.string "location"
    t.text "message"
    t.string "phone"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["event_date"], name: "index_quotes_on_event_date"
    t.index ["status"], name: "index_quotes_on_status"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "order_id"
    t.integer "rating", null: false
    t.integer "report_count", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["order_id"], name: "index_reviews_on_order_id"
    t.index ["status"], name: "index_reviews_on_status"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "language", default: "fr", null: false
    t.boolean "notifications_email_order", default: true
    t.boolean "notifications_email_promotional", default: false
    t.boolean "notifications_email_quote", default: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "full_name"
    t.string "last_name"
    t.string "password_digest"
    t.string "phone"
    t.string "role", default: "customer", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "invoices", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_events", "payments"
  add_foreign_key "payments", "orders"
  add_foreign_key "product_options", "products"
  add_foreign_key "product_price_changes", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "quotes", "users"
  add_foreign_key "reviews", "orders"
  add_foreign_key "reviews", "users"
  add_foreign_key "user_preferences", "users"
end
