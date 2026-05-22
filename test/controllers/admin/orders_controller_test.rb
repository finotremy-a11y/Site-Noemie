require "test_helper"

module Admin
  class OrdersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = User.create!(
        email: "nl.cuisinent@gmail.com",
        password: "password123",
        role: "admin"
      )

      @order = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "client@test.com",
        customer_phone: "0600000000",
        subtotal_cents: 2600,
        delivery_fee_cents: 0,
        total_cents: 2600
      )

      login_as_admin
    end

    test "show is accessible for admin" do
      get admin_order_path(@order)

      assert_response :success
      assert_includes response.body, @order.order_number
    end

    test "index accepts sort parameters" do
      get admin_orders_path, params: {
        sort: "total_cents",
        direction: "asc"
      }

      assert_response :success
      assert_includes response.body, "Liste des commandes"
    end

    test "index accepts date range filters" do
      get admin_orders_path, params: {
        date_from: 1.day.ago.to_date.to_s,
        date_to: Date.current.to_s
      }

      assert_response :success
      assert_includes response.body, "Liste des commandes"
    end

    test "status update transitions order and writes audit" do
      patch status_admin_order_path(@order), params: {
        order: {
          status: "cancelled",
          reason: "Client indisponible"
        }
      }

      assert_redirected_to admin_order_path(@order)
      @order.reload
      assert_equal "cancelled", @order.status
      assert_equal 1, AuditLog.where(resource_type: "Order", resource_id: @order.id, action: "update").count
    end

    test "admin can accept a paid order pending validation" do
      @order.update!(status: "pending_validation", payment_status: "pending")
      @order.payments.create!(
        provider: "stripe",
        provider_payment_id: "pi_accept_1",
        status: "pending",
        amount_cents: @order.total_cents,
        currency: "EUR"
      )

      Stripe::PaymentIntent.stub(:capture, OpenStruct.new(id: "pi_accept_1", status: "succeeded")) do
        patch status_admin_order_path(@order), params: {
          order: {
            status: "confirmed",
            reason: "Validation admin"
          }
        }
      end

      assert_redirected_to admin_order_path(@order)
      assert_equal "confirmed", @order.reload.status
    end

    test "admin confirmation captures authorized payment" do
      @order.update!(status: "pending_validation", payment_status: "pending")
      @order.payments.create!(
        provider: "stripe",
        provider_payment_id: "pi_capture_1",
        status: "pending",
        amount_cents: @order.total_cents,
        currency: "EUR"
      )

      Stripe::PaymentIntent.stub(:capture, OpenStruct.new(id: "pi_capture_1", status: "succeeded")) do
        patch status_admin_order_path(@order), params: {
          order: {
            status: "confirmed",
            reason: "Validation admin"
          }
        }
      end

      assert_redirected_to admin_order_path(@order)
      @order.reload
      assert_equal "confirmed", @order.status
      assert_equal "paid", @order.payment_status
      assert_equal "paid", @order.payments.last.status
    end

    test "admin can refuse a paid order pending validation" do
      @order.update!(status: "pending_validation", payment_status: "paid")

      patch status_admin_order_path(@order), params: {
        order: {
          status: "cancelled",
          reason: "Indisponibilite"
        }
      }

      assert_redirected_to admin_order_path(@order)
      assert_equal "cancelled", @order.reload.status
    end

    test "admin refusal cancels authorized payment hold" do
      @order.update!(status: "pending_validation", payment_status: "pending")
      @order.payments.create!(
        provider: "stripe",
        provider_payment_id: "pi_cancel_1",
        status: "pending",
        amount_cents: @order.total_cents,
        currency: "EUR"
      )

      Stripe::PaymentIntent.stub(:cancel, OpenStruct.new(id: "pi_cancel_1", status: "canceled")) do
        patch status_admin_order_path(@order), params: {
          order: {
            status: "cancelled",
            reason: "Refus admin"
          }
        }
      end

      assert_redirected_to admin_order_path(@order)
      @order.reload
      assert_equal "cancelled", @order.status
      assert_equal "failed", @order.payment_status
      assert_equal "failed", @order.payments.last.status
    end

    test "bulk status updates selected orders" do
      other_order = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "client2@test.com",
        customer_phone: "0600000001",
        subtotal_cents: 1800,
        delivery_fee_cents: 0,
        total_cents: 1800
      )

      patch bulk_status_admin_orders_path, params: {
        order_ids: [ @order.id, other_order.id ],
        bulk: { status: "cancelled" }
      }

      assert_redirected_to admin_orders_path
      assert_equal "cancelled", @order.reload.status
      assert_equal "cancelled", other_order.reload.status
    end

    private

    def login_as_admin
      post "/auth/login", params: {
        email: @admin.email,
        password: "password123"
      }
      follow_redirect!
    end
  end
end
