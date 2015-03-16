module Api
  class BaseController < ActionController::Base
    rescue_from StandardError, with: :api_error

    def api_error(e)
      # Uber gem has stupid errors.
      if e.message == "the server responded with status 422"
        render json: { error: "Looks like you've entered an invalid location. Try again." }, status: 500
      else
        render json: { error: e.message }, status: 500
      end
    end
  end
end
