module Notifications
  class SendOrderStatusUpdateEmailJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.minutes, attempts: 3

    def perform(order_id, new_status)
      order = Order.find(order_id)

      if order.user&.preference&.notifications_email_order
        NotificationMailer.order_status_update(order_id, new_status).deliver_later
      end

      log_notification(order, "order_status_update", new_status)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Order #{order_id} not found for status update email")
    end

    private

    def log_notification(order, notification_type, status)
      Rails.logger.info("Sent #{notification_type} (#{status}) for order #{order.order_number}")
    end
  end
end
