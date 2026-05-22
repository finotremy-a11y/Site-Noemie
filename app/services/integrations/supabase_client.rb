module Integrations
  class SupabaseClient
    def initialize(base_url: ENV["SUPABASE_URL"], service_role_key: ENV["SUPABASE_SERVICE_ROLE_KEY"])
      @base_url = base_url
      @service_role_key = service_role_key
    end

    def table(path)
      connection.get("/rest/v1/#{path}")
    end

    private

    attr_reader :base_url, :service_role_key

    def connection
      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json
        f.headers["apikey"] = service_role_key
        f.headers["Authorization"] = "Bearer #{service_role_key}"
      end
    end
  end
end
