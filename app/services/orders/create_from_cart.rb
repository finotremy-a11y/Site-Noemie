module Orders
  class CreateFromCart
    class ValidationError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Invalid order context")
      end
    end

    def initialize(cart:, attrs:)
      @cart = cart
      @attrs = attrs
    end

    def call
      validate!

      Order.transaction do
        order = Order.create!(
          user_id: cart.user_id,
          status: "pending_payment",
          payment_status: "pending",
          service_mode: attrs.fetch("service_mode"),
          customer_email: attrs.fetch("customer_email"),
          customer_phone: attrs.fetch("customer_phone"),
          delivery_address: attrs["delivery_address"],
          requested_at: parse_requested_at(attrs["requested_at"])
        )

        cart.cart_items.includes(:product).find_each do |item|
          order.order_items.create!(
            product_id: item.product_id,
            name: item.product.name,
            quantity: item.quantity,
            unit_price_cents: item.unit_price_cents,
            line_total_cents: item.line_total_cents,
            options: item.options
          )
        end

        subtotal = order.order_items.sum(:line_total_cents)
        distance_km = attrs["delivery_distance_km"].to_f
        delivery_fee = if order.service_mode == "delivery"
          Delivery::Pricing.fee_cents_for(distance_km) || 0
        else
          0
        end
        vat = ((subtotal + delivery_fee) * vat_rate).round
        total = subtotal + delivery_fee + vat

        order.update!(
          subtotal_cents: subtotal,
          delivery_fee_cents: delivery_fee,
          total_cents: total
        )

        cart.update!(status: "converted")
        order
      end
    end

    private

    attr_reader :cart, :attrs

    def validate!
      details = {}

      details[:cart] = "empty" if cart.cart_items.empty?

      service_mode = attrs["service_mode"].to_s
      details[:service_mode] = "must be pickup or delivery" unless Order::SERVICE_MODES.include?(service_mode)

      details[:customer_email] = "required" if attrs["customer_email"].blank?
      details[:customer_phone] = "required" if attrs["customer_phone"].blank?

      if service_mode == "delivery"
        details[:delivery_address] = "required" if attrs["delivery_address"].blank?
        minimum_cents = BusinessSetting.current.delivery_min_order_cents
        details[:minimum_amount] = "delivery requires at least #{minimum_cents} cents" if cart.subtotal_cents < minimum_cents

        distance_km = attrs["delivery_distance_km"].to_f
        details[:delivery_distance_km] = "required" if distance_km <= 0
        if distance_km > 0 && !Delivery::Pricing.allowed?(distance_km)
          details[:delivery_distance_km] = "delivery is only available up to 20 km"
        end
      end

      unavailable_item = cart.cart_items.includes(:product).detect do |item|
        !item.product.active? || item.product.stock_quantity < item.quantity
      end

      details[:stock] = "one or more items are unavailable" if unavailable_item

      raise ValidationError, details if details.any?
    end

    def parse_requested_at(value)
      return nil if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError
      nil
    end

    def vat_rate
      BusinessSetting.current.vat_rate.to_f
    end
  end
end
