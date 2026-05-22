require "test_helper"

class Api::V1::HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns healthy payload" do
    get "/api/v1/health"

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal "ok", body["status"]
    assert_equal "site_noemie_api", body["service"]
    assert body["timestamp_utc"].present?
  end
end
