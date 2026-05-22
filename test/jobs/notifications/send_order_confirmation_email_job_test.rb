require "test_helper"

class Notifications::SendOrderConfirmationEmailJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(email: "job@example.com", role: "customer", active: true)
    @order = @user.orders.create!(
      order_number: "ORD-EMAIL-001",
      status: "pending_payment",
      payment_status: "pending",
      service_mode: "delivery",
      subtotal_cents: 1000,
      delivery_fee_cents: 0,
      total_cents: 1000
    )
  end

  test "enqueues job" do
    assert_enqueued_with(
      job: Notifications::SendOrderConfirmationEmailJob,
      args: [ @order.id ]
    ) do
      Notifications::SendOrderConfirmationEmailJob.perform_later(@order.id)
    end
  end

  test "performs job and sends email" do
    assert_enqueued_jobs 0

    Notifications::SendOrderConfirmationEmailJob.perform_later(@order.id)

    assert_enqueued_jobs 1

    # Simulate job execution
    perform_enqueued_jobs

    # Verify email was queued (would deliver_later)
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob
  end

  test "handles missing order gracefully" do
    assert_no_enqueued_jobs do
      perform_enqueued_jobs do
        Notifications::SendOrderConfirmationEmailJob.perform_later(999999)
      end
    end
  end
end
