class AddReviewReportCount < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :report_count, :integer, null: false, default: 0
    add_index :reviews, :status
  end
end
