class UberApi
  class << self
    def uber_client
      @client ||= Uber::Client.new do |config|
        config.server_token  = ENV['UBER_SERVER_TOKEN']
        config.client_id     = ENV['UBER_APP_ID']
        config.client_secret = ENV['USER_SECRET']
      end
    end
  end
end
