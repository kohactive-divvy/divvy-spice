module Api
  class BaseController < ActionController::Base
    rescue_from StandardError, with: :api_error

    def api_error(e)
      render json: {error: e.message}, status: 500
    end
  end
end