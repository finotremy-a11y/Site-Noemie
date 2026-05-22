require "test_helper"

module Api
  module V1
    class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
      FakeEvent = Struct.new(:id, :type, :data, :created) do
        def to_hash
          {
            "id" => id,
            "type" => type
          }
        end
      end

      FakeData = Struct.new(:object)
      FakeSession = Struct.new(:id, :metadata, :client_reference_id, :amount_total, :currency, :payment_status, :payment_intent)

      setup do
        @order = Order.create!(
          status: "pending_payment",
          payment_status: "pending",
          service_mode: "pickup",
          customer_email: "client@test.com",
          customer_phone: "0600000000",
          subtotal_cents: 2400,
          delivery_fee_cents: 0,
          total_cents: 2400
        )
      end

      test "completed checkout marks order as paid and pending admin validation" do
        session = FakeSession.new(
          "cs_live_1",
          { "order_id" => @order.id.to_s },
          @order.id.to_s,
          2400,
          "eur",
          "paid",
          "pi_auth_1"
        )
        event = FakeEvent.new("evt_1", "checkout.session.completed", FakeData.new(session), Time.now.to_i)

        Stripe::Webhook.stub(:construct_event, event) do
          ENV.stub(:fetch, "whsec_test") do
            post "/api/v1/payments/webhook", headers: { "Stripe-Signature" => "sig" }
          end
        end

        assert_response :ok
        @order.reload
        assert_equal "pending", @order.payment_status
        assert_equal "pending", @order.payments.last.status
        assert_equal "pi_auth_1", @order.payments.last.provider_payment_id
        assert_equal "pending_validation", @order.status
        assert_equal 1, @order.payments.count
        assert_equal 0, Invoice.where(order_id: @order.id).count
        assert_equal 1, PaymentEvent.where(provider_event_id: "evt_1").count
      end

      test "duplicate event is ignored" do
        PaymentEvent.create!(provider_event_id: "evt_duplicate", event_type: "checkout.session.completed", payload: {})

        session = FakeSession.new(
          "cs_live_dup",
          { "order_id" => @order.id.to_s },
          @order.id.to_s,
          2400,
          "eur",
          "paid",
          "pi_auth_dup"
        )
        event = FakeEvent.new("evt_duplicate", "checkout.session.completed", FakeData.new(session), Time.now.to_i)

        Stripe::Webhook.stub(:construct_event, event) do
          ENV.stub(:fetch, "whsec_test") do
            post "/api/v1/payments/webhook", headers: { "Stripe-Signature" => "sig" }
          end
        end

        assert_response :ok
        assert_equal true, response.parsed_body.dig("processed", "ignored")
      end
    end
  end
end
