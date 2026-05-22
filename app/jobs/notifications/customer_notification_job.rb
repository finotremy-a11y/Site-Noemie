module Notifications
  class CustomerNotificationJob < ApplicationJob
    queue_as :default

    def perform(to:, subject:, lines:)
      Notifications::SendCustomerNotification.new(
        to: to,
        subject: subject,
        lines: Array(lines)
      ).call
    end
  end
end
