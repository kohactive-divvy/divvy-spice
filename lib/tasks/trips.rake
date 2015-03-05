namespace :divvy do

  task :create_station_trips => :environment do
    trips = Trip.select(['from_station_id', 'to_station_id', 'duration']).group(:from_station_id, :to_station_id).average('duration') 
    trips.each do |st|
      station_trip = StationTrip.new(
        from_station_id: st[0][0],
        to_station_id: st[0][1],
        average_duration: st[1].to_i
      )
      if station_trip.save!
        puts "Saved from #{st[0][0]} to #{st[0][1]} with average #{st[1].to_i}"
      else
        puts "ERROR!"
      end
    end
  end

  task :station_trip_counts => :environment do
    trips = Trip.connection.query("SELECT trips.from_station_id, trips.to_station_id, COUNT(*) FROM trips GROUP BY trips.from_station_id, trips.to_station_id")
    trips.each do |trip|
      st = StationTrip.where(from_station_id: trip[0], to_station_id: trip[1]).first
      st.update_attribute(:trip_count, trip[2]) unless st.nil?
      puts "UPDATED FROM #{st.from_station_id} TO #{st.to_station_id}"
    end
  end
end
