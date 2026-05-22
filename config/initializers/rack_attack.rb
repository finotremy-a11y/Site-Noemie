class Rack::Attack
  throttle("req/ip", limit: 120, period: 1.minute) do |request|
    request.ip
  end

  throttle("payments/ip", limit: 20, period: 1.minute) do |request|
    request.ip if request.path.start_with?("/api/v1/payments")
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: { code: "rate_limited", message: "Trop de requetes." } }.to_json ] ]
  end
end
