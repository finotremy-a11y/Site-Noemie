class Invoice < ApplicationRecord
  STATUSES = %w[issued cancelled refunded].freeze

  belongs_to :order

  validates :invoice_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :total_cents, numericality: { greater_than_or_equal_to: 0 }

  after_commit :schedule_pdf_generation, on: :create

  scope :recent, -> { order(issued_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  def pdf_ready?
    pdf_url.present?
  end

  private

  def schedule_pdf_generation
    Documents::UploadInvoiceJob.perform_later(id)
  end
end
