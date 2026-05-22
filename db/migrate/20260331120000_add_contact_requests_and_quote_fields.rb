class AddContactRequestsAndQuoteFields < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_requests do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.text :message, null: false
      t.timestamps
    end
    add_index :contact_requests, :created_at

    add_column :quotes, :location, :string
    add_column :quotes, :budget_cents, :integer
    add_column :quotes, :constraints, :text

    add_index :quotes, :status
    add_index :quotes, :event_date
  end
end
