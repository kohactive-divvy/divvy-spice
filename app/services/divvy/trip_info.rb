module Divvy
  class TripInfo
    class << self
      def call(options)
        origin = options[:origin]
        destination = options[:destination]

        o = Geocoder.search(origin)
        d = Geocoder.search(destination)


        f = RGeo::Geographic.spherical_factory(srid: 4326)
        olat = o[0].geometry["location"]["lat"] rescue raise(StandardError, "Origin location is not valid")
        olng = o[0].geometry["location"]["lng"] rescue raise(StandardError, "Origin location is not valid")
        dlat = d[0].geometry["location"]["lat"] rescue raise(StandardError, "Destination location is not valid")
        dlng = d[0].geometry["location"]["lng"] rescue raise(StandardError, "Destination location is not valid")

        origin_closest_station = Station.all.order("stations.lnglat::geometry <-> 'SRID=4326;POINT(#{olng} #{olat})'::geometry").limit(1).first # rescue raise(StandardError, "No close by stations") 
        destination_closest_station = Station.all.order("stations.lnglat::geometry <-> 'SRID=4326;POINT(#{dlng} #{dlat})'::geometry").limit(1).first # rescue raise(StandardError, "No close by stations") 

        ostring = "#{origin_closest_station.lnglat.y},#{origin_closest_station.lnglat.x}"
        dstring = "#{destination_closest_station.lnglat.y},#{destination_closest_station.lnglat.x}"


        walking_to_directions = GoogleDirections.new("#{olat},#{olng}", ostring, {long_lat: true, mode: "walking"})
        walking_from_directions = GoogleDirections.new(dstring, "#{dlat},#{dlng}", {long_lat: true, mode: "walking"})
        
        biking_directions = GoogleDirections.new(ostring, dstring, {long_lat: true, mode: "bicycling"})
        driving_directions = GoogleDirections.new(ostring, dstring, {long_lat: true, mode: "driving"})


        google_divvy_transit_time = walking_to_directions.drive_time_in_minutes + walking_from_directions.drive_time_in_minutes + biking_directions.drive_time_in_minutes
        
        puts origin_closest_station.inspect
        puts "<----->"
        puts destination_closest_station.inspect

        biking_trip = StationTrip.find_by(from_station_id: origin_closest_station.station_id, to_station_id: destination_closest_station.station_id) || StationTrip.find_by(from_station_id: destination_closest_station.station_id, to_station_id: origin_closest_station.station_id)
        
        divvy_transit_time_avg = (biking_trip.average_duration / 60).to_i + walking_to_directions.drive_time_in_minutes + walking_from_directions.drive_time_in_minutes rescue nil
        divvy_transit_time_min = (biking_trip.fastest_trip / 60).to_i + walking_to_directions.drive_time_in_minutes + walking_from_directions.drive_time_in_minutes rescue nil
        divvy_transit_time_max = (biking_trip.slowest_trip / 60).to_i + walking_to_directions.drive_time_in_minutes + walking_from_directions.drive_time_in_minutes rescue nil
        divvy_trips = biking_trip.trip_count rescue nil

        times = UberApi.uber_client.time_estimations(start_latitude: olat, start_longitude: olng)
        prices = UberApi.uber_client.price_estimations(start_latitude: olat, start_longitude: olng,
                         end_latitude: dlat, end_longitude: dlng)
        
        ubers = {}

        times.each do |t|
          ubers[t.product_id] ||= {}
          ubers[t.product_id][:name] = t.display_name
          ubers[t.product_id][:time] = (t.estimate / 60).to_i + driving_directions.drive_time_in_minutes
        end

        prices.each do |p|
          ubers[p.product_id] ||= {}
          ubers[p.product_id][:name] = p.display_name
          ubers[p.product_id][:price] = p.estimate
          ubers[p.product_id][:surge] = p.surge_multipler
        end

        {
          divvy: {
            origin_latlng: [olat, olng],
            destination_latlng: [dlat, dlng],
            origin_station: origin_closest_station,
            destination_station: destination_closest_station,
            price: "$7",
            google: google_divvy_transit_time,
            avg: divvy_transit_time_avg,
            min: divvy_transit_time_min,
            max: divvy_transit_time_max,
            trips: divvy_trips,
            routes: {
              walking_to: Hash.from_xml(walking_to_directions.xml),
              biking: Hash.from_xml(biking_directions.xml),
              walking_from: Hash.from_xml(walking_from_directions.xml)
            }
          },
          uber: ubers,
          routes: {
            driving: Hash.from_xml(driving_directions.xml),
          }
        }
        
      end    
    end
  end
end
