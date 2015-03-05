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

        puts origin_closest_station.inspect
        puts destination_closest_station.inspect

        directions = GoogleDirections.new(origin, destination, {mode: "bicycling"})
        {
          total_transit_time: directions.drive_time_in_minutes
        }
      end    
    end
  end
end