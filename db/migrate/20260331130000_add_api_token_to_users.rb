class AddApiTokenToUsers < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true

    MigrationUser.reset_column_information
    MigrationUser.find_each do |user|
      user.update_column(:api_token, SecureRandom.base58(24))
    end
  end

  def down
    remove_index :users, :api_token
    remove_column :users, :api_token
  end
end
