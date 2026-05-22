require "test_helper"

module Api
  module V1
    module Me
      class AddressesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = User.create!(email: "test@example.com", role: "customer", active: true)
          @user.generate_api_token
          @user.save!
          @token = @user.api_token
        end

        test "index returns user addresses" do
          @user.addresses.create!(
            address_type: "delivery",
            full_name: "John Doe",
            street: "123 Main St",
            city: "Paris",
            postal_code: "75001",
            country: "FR",
            phone: "0634936801"
          )

          get "/api/v1/me/addresses", headers: { "X-Customer-Token" => @token }
          assert_response :success

          json = JSON.parse(response.body)
          assert json["data"].is_a?(Array)
          assert_equal 1, json["data"].length
        end

        test "create address requires authentication" do
          post "/api/v1/me/addresses", params: { address: {} }
          assert_response :unauthorized
        end

        test "create address with valid params" do
          post "/api/v1/me/addresses",
               params: {
                 address: {
                   address_type: "delivery",
                   full_name: "Jane Doe",
                   street: "456 Elm St",
                   city: "Lyon",
                   postal_code: "69001",
                   country: "FR",
                   phone: "0987654321"
                 }
               },
               headers: { "X-Customer-Token" => @token }

          assert_response :created
          json = JSON.parse(response.body)
          assert_equal "Jane Doe", json.dig("data", "full_name")
        end

        test "show address" do
          addr = @user.addresses.create!(
            address_type: "billing",
            full_name: "Bob Smith",
            street: "789 Oak Ave",
            city: "Marseille",
            postal_code: "13001",
            country: "FR",
            phone: "0555555555"
          )

          get "/api/v1/me/addresses/#{addr.id}", headers: { "X-Customer-Token" => @token }
          assert_response :success

          json = JSON.parse(response.body)
          assert_equal "Bob Smith", json.dig("data", "full_name")
        end

        test "update address" do
          addr = @user.addresses.create!(
            address_type: "delivery",
            full_name: "Alice",
            street: "111 Street",
            city: "Toulouse",
            postal_code: "31000",
            country: "FR",
            phone: "0111111111"
          )

          patch "/api/v1/me/addresses/#{addr.id}",
                params: {
                  address: { full_name: "Alice Updated" }
                },
                headers: { "X-Customer-Token" => @token }

          assert_response :success
          json = JSON.parse(response.body)
          assert_equal "Alice Updated", json.dig("data", "full_name")
        end

        test "destroy address" do
          addr = @user.addresses.create!(
            address_type: "delivery",
            full_name: "Delete Me",
            street: "999 Delete St",
            city: "Nice",
            postal_code: "06000",
            country: "FR",
            phone: "0999999999"
          )

          delete "/api/v1/me/addresses/#{addr.id}", headers: { "X-Customer-Token" => @token }
          assert_response :ok
          assert_raises(ActiveRecord::RecordNotFound) { Address.find(addr.id) }
        end
      end
    end
  end
end
