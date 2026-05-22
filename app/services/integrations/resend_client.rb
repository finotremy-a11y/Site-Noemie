module Integrations
  class ResendClient
    BASE_URL = "https://api.resend.com"

    def initialize(api_key: ENV["RESEND_API_KEY"])
      @api_key = api_key
    end

    def send_email(to:, subject:, html: nil, text: nil, from: ENV.fetch("EMAIL_FROM", "nl.cuisinent@gmail.com"))
      connection.post("/emails") do |request|
        request.body = {
          from: from,
          to: Array(to),
          subject: subject,
          html: html,
          text: text
        }
      end.body
    end

    private

    attr_reader :api_key

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json
        f.headers["Authorization"] = "Bearer #{api_key}"
        f.headers["Content-Type"] = "application/json"
      end
    end
  end
end
