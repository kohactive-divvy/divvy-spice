module Api
  class TripsController < BaseController
    def index
      result = Divvy::TripInfo.call(origin: params[:origin], destination: params[:destination])
      render json: result
    end
  end
end