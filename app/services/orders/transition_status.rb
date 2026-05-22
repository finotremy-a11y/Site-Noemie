module Orders
  class TransitionStatus
    class ValidationError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Invalid status transition")
      end
    end

    class ConflictError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Status transition conflict")
      end
    end

    def initialize(order:, to_status:, actor:, request_id:, reason: nil)
      @order = order
      @to_status = to_status.to_s
      @actor = actor
      @request_id = request_id
      @reason = reason
    end

    def call
      validate_input!
      validate_transition!

      Order.transaction do
        from_status = order.status

        if to_status == "confirmed" && order.status == "pending_validation" && order.payments.where(provider: "stripe", status: "pending").exists?
          Payments::CaptureAuthorization.new(order: order).call
        end

        if to_status == "cancelled" && order.status == "pending_validation"
          Payments::CancelAuthorization.new(order: order).call
        end

        order.update!(status: to_status)

        AuditLog.create!(
          user_id: actor&.id,
          action: "update",
          resource_type: "Order",
          resource_id: order.id,
          request_id: request_id,
          metadata: {
            status: [ from_status, to_status ],
            reason: reason
          }
        )

        # Queue email notification asynchronously
        Notifications::SendOrderStatusUpdateEmailJob.perform_later(order.id, to_status)

        # Trigger invoice generation if order is now paid
        if to_status == "confirmed" && order.invoice.blank?
          Orders::IssueInvoice.new(order: order).call
        end

        order
      end
    end

    private

    attr_reader :order, :to_status, :actor, :request_id, :reason

    def validate_input!
      details = {}
      details[:status] = "invalid" unless Order::STATUSES.include?(to_status)
      details[:reason] = "required when cancelling" if to_status == "cancelled" && reason.blank?

      raise ValidationError, details if details.any?
    end

    def validate_transition!
      if to_status == "confirmed" && !%w[pending paid].include?(order.payment_status)
        raise ConflictError, {
          current_status: order.status,
          requested_status: to_status,
          payment_status: order.payment_status,
          reason: "payment_authorization_required"
        }
      end

      return if order.can_transition_to?(to_status)

      raise ConflictError, {
        current_status: order.status,
        requested_status: to_status,
        allowed: Order::ALLOWED_TRANSITIONS.fetch(order.status, [])
      }
    end
  end
end
