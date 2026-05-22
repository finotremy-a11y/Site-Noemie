class Cart
  class Recalculate
    Result = Struct.new(:subtotal_cents, :delivery_fee_cents, :vat_cents, :total_cents, keyword_init: true)

    def initialize(cart:, service_mode: "pickup")
      @cart = cart
      @service_mode = service_mode
    end

    def call
      subtotal = cart.subtotal_cents
      delivery_fee = cart.delivery_fee_cents(service_mode)
      vat = cart.vat_cents(service_mode)

      Result.new(
        subtotal_cents: subtotal,
        delivery_fee_cents: delivery_fee,
        vat_cents: vat,
        total_cents: subtotal + delivery_fee + vat
      )
    end

    private

    attr_reader :cart, :service_mode
  end
end
