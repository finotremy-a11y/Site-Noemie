module Notifications
  class SendOrderConfirmationEmailJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.minutes, attempts: 3

    def perform(order_id)
      order = Order.find(order_id)

      if order.user&.preference&.notifications_email_order
        NotificationMailer.order_confirmation(order_id).deliver_later
      end

      log_notification(order, "order_confirmation")
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Order #{order_id} not found for email")
    end

    private

    def log_notification(order, notification_type)
      Rails.logger.info("Sent #{notification_type} for order #{order.order_number}")
    end
  end
end
