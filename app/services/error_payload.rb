class ErrorPayload
  attr_reader :code, :message, :details, :status

  def self.build(code:, message:, details: {})
    {
      error: {
        code: code,
        message: message,
        details: details
      }
    }
  end

  def initialize(code:, message:, details: {}, status: :internal_server_error)
    @code = code
    @message = message
    @details = details
    @status = status
  end

  def to_json(*args)
    {
      error: {
        code: code,
        message: message,
        details: details
      }
    }.to_json(*args)
  end

  def to_h
    {
      error: {
        code: code,
        message: message,
        details: details
      }
    }
  end
end
