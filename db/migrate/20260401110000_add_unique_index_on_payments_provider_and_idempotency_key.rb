class AddUniqueIndexOnPaymentsProviderAndIdempotencyKey < ActiveRecord::Migration[8.1]
  def change
    remove_index :payments, :idempotency_key if index_exists?(:payments, :idempotency_key)

    add_index :payments,
              [ :provider, :idempotency_key ],
              unique: true,
              where: "idempotency_key IS NOT NULL",
              name: "idx_payments_provider_idempotency_key_unique"
  end
end
