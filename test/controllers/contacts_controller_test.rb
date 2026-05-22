require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "new displays business contact details and nested form fields" do
    get contact_path

    assert_response :success
    assert_includes response.body, "nl.cuisinent@gmail.com"
    assert_includes response.body, "1463 route d'avignon"
    assert_select 'input[name="contact_request[name]"]'
    assert_select 'textarea[name="contact_request[message]"]'
  end

  test "create accepts nested contact_request params" do
    notified = false

    Notifications::InquiryNotificationJob.stub(:perform_later, ->(**) { notified = true }) do
      assert_difference("ContactRequest.count", 1) do
        post contacts_path, params: {
          contact_request: {
            name: "Client test",
            email: "client@example.com",
            phone: "0600000000",
            subject: "Question",
            message: "Bonjour, je souhaite plus d'informations."
          }
        }
      end
    end

    assert notified
    assert_redirected_to root_path
  end
end
