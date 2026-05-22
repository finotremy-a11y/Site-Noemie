module Notifications
  class SendCustomerNotification
    def initialize(to:, subject:, lines:)
      @to = to
      @subject = subject
      @lines = lines
    end

    def call
      return if ENV["RESEND_API_KEY"].blank?
      return if to.blank?

      Integrations::ResendClient.new.send_email(
        to: to,
        subject: subject,
        text: lines.join("\n")
      )
    rescue Faraday::Error => error
      Rails.logger.warn(
        {
          source: "notifications.send_customer_notification",
          error_class: error.class.name,
          error_message: error.message
        }.to_json
      )
      nil
    end

    private

    attr_reader :to, :subject, :lines
  end
end
