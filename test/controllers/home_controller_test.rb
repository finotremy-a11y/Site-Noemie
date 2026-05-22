require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders homepage with premium proof points" do
    get root_url

    assert_response :success
    assert_includes response.body, "Des burgers qui changent tout"
    assert_includes response.body, "Une expérience pensée pour aller vite"
    assert_includes response.body, "Comment ça marche"
    assert_includes response.body, "Événements privés, mariages, anniversaires"
  end
end
