class AddPdfUrlToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :pdf_url, :string
  end
end
