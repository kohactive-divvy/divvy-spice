namespace :divvy do

  task :create_station_trips => :environment do
    Trip.all.group(:from_station_id, :to_station_id).each do |trip|
      puts trip.inspect
    end


    # This is bad.
    # 
    # 
    # Station.all.each do |from|
    #   from_station_id = from.station_id
    #   Station.all.each do |to|
    #     to_station_id = to.station_id
    #     trips = Trip.where(from_station_id: from_station_id, to_station_id: to_station_id).order(:duration)
    #     st = StationTrip.new
    #     st.from_station_id = from_station_id
    #     st.to_station_id = to_station_id
    #     st.trip_count = trips.count
    #     st.average_duration = trips.average(:duration).to_i
    #     st.fastest_trip = trips.first.duration
    #     st.slowest_trip = trips.last.duration
    #     puts "#{trips.count} from #{from_station_id} to #{to_station_id}" if st.save!
    #   end
    # end
  end
end
