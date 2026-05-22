module Notifications
  class SendInquiryNotification
    def initialize(subject:, lines:)
      @subject = subject
      @lines = lines
    end

    def call
      return if ENV["RESEND_API_KEY"].blank?

      Integrations::ResendClient.new.send_email(
        to: admin_destination,
        subject: subject,
        text: lines.join("\n")
      )
    rescue Faraday::Error => error
      Rails.logger.warn(
        {
          source: "notifications.send_inquiry_notification",
          error_class: error.class.name,
          error_message: error.message
        }.to_json
      )
      nil
    end

    private

    attr_reader :subject, :lines

    def admin_destination
      ENV.fetch("ADMIN_NOTIFICATION_EMAIL", ENV.fetch("EMAIL_FROM", "nl.cuisinent@gmail.com"))
    end
  end
end
