module Api
  module V1
    module Admin
      module Dashboard
        class SummariesController < Api::V1::Admin::BaseController
          def show
            payload = ::Admin::Dashboard::SummaryQuery.new(
              period_days: period_days,
              date_from: safe_date(params[:date_from]),
              date_to: safe_date(params[:date_to])
            ).call

            render json: { data: payload }, status: :ok
          end

          private

          def period_days
            value = params[:period_days].to_i
            [ 7, 30, 90 ].include?(value) ? value : 30
          end

          def safe_date(value)
            return if value.blank?

            Date.parse(value)
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end
