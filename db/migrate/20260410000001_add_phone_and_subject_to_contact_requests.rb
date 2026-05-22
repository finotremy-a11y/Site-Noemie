class AddPhoneAndSubjectToContactRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :contact_requests, :phone, :string
    add_column :contact_requests, :subject, :string
  end
end
