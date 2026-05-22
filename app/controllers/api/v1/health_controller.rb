module Api
  module V1
    class HealthController < BaseController
      def show
        render json: {
          status: "ok",
          service: "site_noemie_api",
          timestamp_utc: Time.current.utc.iso8601
        }
      end
    end
  end
end
