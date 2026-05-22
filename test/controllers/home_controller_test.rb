require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders homepage" do
    get root_url

    assert_response :success
    assert_match "N&L Cuisinent", response.body
  end
end
