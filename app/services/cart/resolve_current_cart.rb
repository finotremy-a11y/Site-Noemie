class Cart
  class ResolveCurrentCart
    class ValidationError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Invalid cart context")
      end
    end

    def initialize(session_token:, user_id: nil)
      @session_token = session_token.to_s.strip
      @user_id = user_id
    end

    def call
      validate!

      Cart.open_state.find_or_create_by!(session_token: session_token) do |cart|
        cart.user_id = user_id
      end
    end

    private

    attr_reader :session_token, :user_id

    def validate!
      return if session_token.present?

      raise ValidationError, { session_token: "required" }
    end
  end
end
