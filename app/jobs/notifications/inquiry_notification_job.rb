module Notifications
  class InquiryNotificationJob < ApplicationJob
    queue_as :default

    def perform(subject:, lines:)
      Notifications::SendInquiryNotification.new(subject: subject, lines: Array(lines)).call
    end
  end
end
