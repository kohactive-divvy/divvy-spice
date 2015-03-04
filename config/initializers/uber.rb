module UberApi
  def self.included(base)

    def base.user_client
      @client ||= Uber::Client.new do |config|
        config.server_token  = UBER_SERVER_TOKEN
        config.client_id     = UBER_APP_ID
        config.client_secret = USER_SECRET
      end
    end
  end

end
