namespace :divvy do

  task :add_points => :environment do

    Station.all.each do |station|
      point = RGeo::Geographic.spherical_factory(srid: 4326).point(station.lng, station.lat)
      station.update_attribute(:lnglat, point)
    end
  end 
end
