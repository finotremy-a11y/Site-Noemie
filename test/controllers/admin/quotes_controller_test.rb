require "test_helper"

module Admin
  class QuotesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = User.create!(
        email: "nl.cuisinent@gmail.com",
        password: "password123",
        role: "admin"
      )

      @quote = Quote.create!(
        email: "client-quote@test.com",
        phone: "0600000000",
        event_type: "Mariage",
        guest_count: 80,
        event_date: 2.weeks.from_now,
        message: "Besoin d'un menu complet",
        status: "new"
      )

      login_as_admin
    end

    test "index accepts filters and sort params" do
      get admin_quotes_path, params: {
        status: "new",
        q: "mariage",
        date_from: Date.current.to_s,
        date_to: 1.month.from_now.to_date.to_s,
        sort: "event_date",
        direction: "asc"
      }

      assert_response :success
      assert_includes response.body, "Demandes de devis"
    end

    test "status update changes quote state" do
      patch status_admin_quote_path(@quote), params: {
        quote: { status: "processed" }
      }

      assert_redirected_to admin_quote_path(@quote)
      @quote.reload
      assert_equal "processed", @quote.status
      assert_equal 1, AuditLog.where(resource_type: "Quote", resource_id: @quote.id, action: "quote_status_changed").count
    end

    test "bulk status updates selected quotes" do
      other_quote = Quote.create!(
        email: "client-quote-2@test.com",
        phone: "0600000001",
        event_type: "Bapteme",
        guest_count: 30,
        event_date: 1.month.from_now,
        message: "Buffet froid",
        status: "new"
      )

      patch bulk_status_admin_quotes_path, params: {
        quote_ids: [ @quote.id, other_quote.id ],
        bulk: { status: "processed" }
      }

      assert_redirected_to admin_quotes_path
      assert_equal "processed", @quote.reload.status
      assert_equal "processed", other_quote.reload.status
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
